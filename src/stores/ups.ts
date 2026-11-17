import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { upsApi } from '@/api/ups'
import type { UPSStatus } from '@/types/ups'

export const useUPSStore = defineStore('ups', () => {
  const status = ref<UPSStatus | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const autoRefresh = ref(true)
  const refreshInterval = ref(5000)

  let refreshTimer: number | null = null

  // 计算属性
  const batteryStatus = computed(() => {
    if (!status.value) return 'unknown'
    const charge = status.value.battery.charge
    if (charge > 80) return 'good'
    if (charge > 30) return 'warning'
    return 'critical'
  })

  const isOnline = computed(() => status.value?.status === 'online')
  const isOnBattery = computed(() => status.value?.status === 'onbatt')

  // 获取UPS状态
  async function fetchStatus(upsName: string = 'ups') {
    loading.value = true
    error.value = null
    try {
      status.value = await upsApi.getStatus(upsName)
    } catch (e) {
      error.value = e instanceof Error ? e.message : '获取 UPS 状态失败'
      console.error(e)
    } finally {
      loading.value = false
    }
  }

  // 启动自动刷新
  function startAutoRefresh(upsName: string = 'ups') {
    if (refreshTimer) {
      clearInterval(refreshTimer)
    }
    
    fetchStatus(upsName)
    
    if (autoRefresh.value) {
      refreshTimer = window.setInterval(() => {
        fetchStatus(upsName)
      }, refreshInterval.value)
    }
  }

  // 停止自动刷新
  function stopAutoRefresh() {
    if (refreshTimer) {
      clearInterval(refreshTimer)
      refreshTimer = null
    }
  }

  // 切换自动刷新
  function toggleAutoRefresh(upsName: string = 'ups') {
    autoRefresh.value = !autoRefresh.value
    if (autoRefresh.value) {
      startAutoRefresh(upsName)
    } else {
      stopAutoRefresh()
    }
  }

  return {
    status,
    loading,
    error,
    autoRefresh,
    refreshInterval,
    batteryStatus,
    isOnline,
    isOnBattery,
    fetchStatus,
    startAutoRefresh,
    stopAutoRefresh,
    toggleAutoRefresh
  }
})
