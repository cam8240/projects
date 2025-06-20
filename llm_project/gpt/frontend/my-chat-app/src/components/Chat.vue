<script setup>
import { ref, onMounted, nextTick } from 'vue'
import { marked } from 'marked'
import hljs from 'highlight.js'
import 'highlight.js/styles/github-dark.css'

const chat = ref(null)
const msgInput = ref('')
const mode = ref('friendly')
const session_id = 'default'
const error = ref(null)
const isTyping = ref(false)
const textarea = ref(null)

function autoGrow() {
  const el = textarea.value
  if (!el) return
  el.style.height = 'auto'
  el.style.height = Math.min(el.scrollHeight, 192) + 'px'
}

function handleKeyDown(event) {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault()
    send()
  }
}

marked.setOptions({
  highlight: code => hljs.highlightAuto(code).value
})

function scrollToBottom() {
  nextTick(() => {
    chat.value.scrollTop = chat.value.scrollHeight
  })
}

function addCopyButtons(container, text) {
  const copyBtn = document.createElement('button')
  copyBtn.className = 'copy-message'
  copyBtn.innerText = 'Copy'
  copyBtn.onclick = () => navigator.clipboard.writeText(text)
  container.appendChild(copyBtn)

  container.querySelectorAll('pre code').forEach(block => {
    const button = document.createElement('button')
    button.className = 'copy-code'
    button.innerText = 'Copy Code'
    button.onclick = () => navigator.clipboard.writeText(block.innerText)
    block.parentNode.style.position = 'relative'
    block.parentNode.appendChild(button)
  })
}

function renderMessage(content, role) {
  const container = document.createElement('div')
  container.className = `bubble ${role}`

  if (role === 'user') {
    const safeText = content
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/\n/g, '<br>')

    container.innerHTML = `<p>${safeText}</p>`
  } else {
    container.innerHTML = marked.parse(content)
  }

  if (role !== 'user') {
    container.querySelectorAll('pre').forEach(pre => {
      const copyBtn = document.createElement('button')
      copyBtn.className = 'copy-btn code-copy'

      const img = document.createElement('img')
      img.src = '/src/assets/copy-icon.svg'
      img.alt = 'Copy'
      img.style.width = '20px'
      img.style.height = '20px'
      img.style.filter = 'brightness(0) invert(1)'

      copyBtn.appendChild(img)
      copyBtn.style.position = 'absolute'
      copyBtn.style.top = '5px'
      copyBtn.style.right = '5px'
      pre.style.position = 'relative'

      copyBtn.addEventListener('click', () => {
        navigator.clipboard.writeText(pre.innerText).catch(err =>
          console.error('Failed to copy code:', err)
        )
      })

      pre.appendChild(copyBtn)
    })

    if (!content.includes('```')) {
      const text = container.textContent || ''
      const bottomBtn = document.createElement('button')
      bottomBtn.className = 'copy-btn message-copy'

      const img = document.createElement('img')
      img.src = '/src/assets/copy-icon.svg'
      img.alt = 'Copy'
      img.style.width = '20px'
      img.style.height = '20px'
      img.style.filter = 'brightness(0) invert(1)'

      bottomBtn.appendChild(img)
      bottomBtn.addEventListener('click', () => {
        navigator.clipboard.writeText(text).catch(err =>
          console.error('Failed to copy message:', err)
        )
      })

      const wrapper = document.createElement('div')
      wrapper.style.marginTop = '0.5rem'
      wrapper.appendChild(bottomBtn)
      container.appendChild(wrapper)
    }
  }

  chat.value.appendChild(container)
  container.scrollIntoView({ behavior: 'smooth' })
}

function addMessage(content, role) {
  renderMessage(content, role)

  const messages = JSON.parse(localStorage.getItem('messages') || '[]')
  messages.push({ content, role })
  localStorage.setItem('messages', JSON.stringify(messages))
}

async function trySend(message, retries = 3, currentMode) {
  isTyping.value = true

  const loadingEl = document.createElement('div')
  loadingEl.className = 'bubble assistant loading'
  loadingEl.textContent = '...'
  chat.value.appendChild(loadingEl)
  scrollToBottom()

  try {
    const res = await fetch('http://localhost:5000/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message, mode: currentMode, session_id })
    })

    const data = await res.json()
    chat.value.removeChild(loadingEl)
    isTyping.value = false

    if (data.reply) {
      addMessage(data.reply, 'assistant')
    } else if (data.error) {
      error.value = 'Server Error: ' + data.error
    } else {
      error.value = 'Unknown error occurred.'
    }
  } catch (err) {
    if (retries > 0) {
      setTimeout(() => trySend(message, retries - 1, currentMode), 1000)
    } else {
      chat.value.removeChild(loadingEl)
      isTyping.value = false
      error.value = 'Failed to connect after multiple attempts.'
    }
  }
}

function send(event) {
  if (event) event.preventDefault()
  const message = msgInput.value.trim()
  if (!message) return

  addMessage(message, 'user')
  msgInput.value = ''
  error.value = null

  nextTick(() => {
    if (textarea.value) {
      textarea.value.style.height = 'auto'
    }
  })

  trySend(message, 3, mode.value)
}

function clearChat() {
  localStorage.removeItem('messages')
  document.querySelector('.chat-inner').innerHTML = ''
}

onMounted(() => {
  chat.value = document.querySelector('.chat-inner')
  const saved = JSON.parse(localStorage.getItem('messages') || '[]')
  for (const { content, role } of saved) {
    renderMessage(content, role)
  }
})
</script>

<template>
  <router-view />
  <div class="app-container">
    <header>
      <h1>Chat</h1>
      <div class="header-controls">
        <button class="clear-btn" @click="clearChat">Clear Chat</button>
        <select v-model="mode" class="top-left-select">
          <option value="friendly">Friendly</option>
          <option value="tutor">Tutor</option>
          <option value="coder">Coder</option>
        </select>
      </div>
    </header>

    <div v-if="error" class="error-banner">{{ error }}</div>

    <div id="chat">
      <div class="chat-inner"></div>
    </div>

    <footer>
      <form @submit="send">
        <textarea
          ref="textarea"
          v-model="msgInput"
          class="chat-textarea"
          rows="1"
          placeholder="Type your message..."
          @input="autoGrow"
          @keydown="handleKeyDown"
          autofocus
        ></textarea>
        <button type="submit">➤</button>
      </form>
    </footer>
  </div>
</template>