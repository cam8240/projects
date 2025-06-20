<template>
  <div class="coach-container">
    <!-- LEFT : static / growing suggestions list -->
    <div class="left-column">
      <div class="suggestions">
        <p v-for="(s, i) in suggestions" :key="i">{{ s }}</p>
      </div>
      <p v-if="camError" class="error">{{ camError }}</p>
    </div>

    <!-- RIGHT : live transcript -->
    <div class="right-column">
      <div ref="transcriptEl" class="transcript">
        <p v-for="(line, i) in transcript" :key="i">{{ line }}</p>
      </div>

      <div class="controls">
        <button @click="toggleSession" :disabled="busy">
          {{ active ? 'Stop' : 'Start' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick, onBeforeUnmount } from 'vue'
import { io } from 'socket.io-client'     /* ★ NEW */

// -----------------------------  UI state  -----------------------------
const suggestions = ref([
  'Maintain eye contact.',
  'Keep answers concise.',
  'Pause to think before speaking.',
])

const active       = ref(false)
const busy         = ref(false)
const transcriptEl = ref(null)
const transcript   = ref([])
const camError     = ref('')

// ----------------------------  media state  ---------------------------
const stream   = ref(null)
const recorder = ref(null)
let   chunkTimer = null

// ----------------------------  socket state ---------------------------
const socket = ref(null)                /* ★ NEW */

// ----------------------------  helpers  -------------------------------
function autoScroll () {
  nextTick(() => {
    transcriptEl.value?.scrollTo({ top: transcriptEl.value.scrollHeight })
  })
}

// ----------------------------  session flow ---------------------------
function toggleSession () {
  if (busy.value) return
  active.value ? stopSession() : startSession()
}

async function startSession () {
  busy.value  = true
  camError.value = ''

  try {
    // still request video track (unused) – keeps MediaRecorder permissions identical
    stream.value = await navigator.mediaDevices.getUserMedia({ audio: true, video: true })
    await nextTick()

    /* ★ NEW: open WebSocket once per session */
    socket.value = io('http://localhost:5000', { transports: ['websocket'] })
    socket.value.on('connect',    () => console.log('[WS] connected'))
    socket.value.on('disconnect', () => console.log('[WS] disconnected'))
    socket.value.on('error',      err => console.error('[WS]', err))
    socket.value.on('transcript', payload => {
      transcript.value.push(payload.text)
      autoScroll()
    })

    // kick off rolling recorders
    chunkTimer = setInterval(startNewRecorder, 6000)
    startNewRecorder()

    active.value = true
  } catch (err) {
    camError.value = err.message || 'Camera/Mic unavailable'
    console.error('startSession error', err)
  } finally {
    busy.value = false
  }
}

function startNewRecorder () {
  const mimeType = 'audio/webm'
  const audioStream = new MediaStream(stream.value.getAudioTracks())

  const rec = new MediaRecorder(audioStream, {
    mimeType,
    audioBitsPerSecond: 128000,
  })
  recorder.value = rec

  rec.onerror = e => {
    camError.value = 'Recording failed: ' + (e.error?.message || 'Unknown')
    console.error('Recorder error', e.error)
  }

  rec.ondataavailable = ev => {
    if (ev.data && ev.data.size > 0 && socket.value?.connected) {
      socket.value.emit('audio_chunk', ev.data)   /* ★ NEW: send via WS */
    }
  }

  rec.start()
  setTimeout(() => {
    if (rec.state !== 'inactive') rec.stop()
  }, 6050)  // 6-s window + tiny overlap
}

function stopSession () {
  clearInterval(chunkTimer)
  chunkTimer = null

  if (recorder.value?.state !== 'inactive') recorder.value.stop()
  stream.value?.getTracks().forEach(t => t.stop())

  socket.value?.disconnect()            /* ★ NEW */
  socket.value = null

  stream.value   = null
  recorder.value = null
  active.value   = false
}

onBeforeUnmount(stopSession)
</script>
