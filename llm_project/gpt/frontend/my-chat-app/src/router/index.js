import { createRouter, createWebHistory } from 'vue-router'
import HelloWorld from '../components/Chat.vue'
import InterviewCoach from '../components/InterviewCoach.vue'

const routes = [
  { path: '/', component: HelloWorld },
  { path: '/coach', component: InterviewCoach }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
