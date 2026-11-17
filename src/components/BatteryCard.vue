<script setup lang="ts">
import { computed } from 'vue'
import { useUPSStore } from '@/stores/ups'

const upsStore = useUPSStore()

const batteryColor = computed(() => {
  const status = upsStore.batteryStatus
  switch (status) {
    case 'good': return 'text-green-400'
    case 'warning': return 'text-yellow-400'
    case 'critical': return 'text-red-400'
    default: return 'text-gray-400'
  }
})

const runtimeText = computed(() => {
  if (!upsStore.status) return '--'
  const seconds = upsStore.status.battery.runtime
  const minutes = Math.floor(seconds / 60)
  return `${minutes} 分钟`
})
</script>

<template>
  <div class="stat-card">
    <div class="flex items-center justify-between mb-3">
      <h3 class="text-lg font-medium text-gray-300">电池状态</h3>
      <svg class="w-6 h-6 text-accent-cyan" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
      </svg>
    </div>
    
    <div v-if="upsStore.status" class="space-y-4">
      <div class="relative">
        <div class="flex items-end justify-between mb-2">
          <span :class="['text-4xl font-bold', batteryColor]">
            {{ upsStore.status.battery.charge }}%
          </span>
          <span class="text-sm text-gray-400">电量</span>
        </div>
        <div class="w-full bg-dark-bg h-3 rounded-full overflow-hidden">
          <div 
            :class="['h-full transition-all duration-500', 
              upsStore.batteryStatus === 'good' ? 'bg-green-400' :
              upsStore.batteryStatus === 'warning' ? 'bg-yellow-400' : 'bg-red-400'
            ]"
            :style="{ width: `${upsStore.status.battery.charge}%` }"
          />
        </div>
      </div>
      
      <div class="grid grid-cols-2 gap-3 pt-3 border-t border-dark-border">
        <div>
          <div class="text-xs text-gray-400 mb-1">剩余时间</div>
          <div class="text-sm font-medium">{{ runtimeText }}</div>
        </div>
        <div>
          <div class="text-xs text-gray-400 mb-1">电池电压</div>
          <div class="text-sm font-medium">{{ upsStore.status.battery.voltage }} V</div>
        </div>
        <div v-if="upsStore.status.battery.temperature" class="col-span-2">
          <div class="text-xs text-gray-400 mb-1">电池温度</div>
          <div class="text-sm font-medium">{{ upsStore.status.battery.temperature }} °C</div>
        </div>
      </div>
    </div>
    
    <div v-else class="text-center text-gray-400 py-8">
      <div class="animate-pulse">加载中...</div>
    </div>
  </div>
</template>
