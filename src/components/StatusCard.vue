<script setup lang="ts">
import { computed } from 'vue'
import { useUPSStore } from '@/stores/ups'

const upsStore = useUPSStore()

const statusColor = computed(() => {
  if (!upsStore.status) return 'text-gray-400'
  switch (upsStore.status.status) {
    case 'online': return 'text-green-400'
    case 'onbatt': return 'text-accent-orange'
    case 'offline': return 'text-red-400'
    default: return 'text-gray-400'
  }
})

const statusText = computed(() => {
  if (!upsStore.status) return '未知'
  switch (upsStore.status.status) {
    case 'online': return '市电正常'
    case 'onbatt': return '电池供电'
    case 'offline': return '离线'
    default: return '未知状态'
  }
})
</script>

<template>
  <div class="stat-card">
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-3">
        <div :class="['w-3 h-3 rounded-full', 
          upsStore.status?.status === 'online' ? 'bg-green-400 animate-pulse' : 
          upsStore.status?.status === 'onbatt' ? 'bg-accent-orange animate-pulse' : 'bg-gray-400'
        ]"/>
        <div>
          <div class="text-sm text-gray-400">当前状态</div>
          <div :class="['text-xl font-semibold', statusColor]">{{ statusText }}</div>
        </div>
      </div>
      
      <div v-if="upsStore.status" class="text-right">
        <div class="text-sm text-gray-400">设备型号</div>
        <div class="text-lg font-medium">{{ upsStore.status.device.model }}</div>
        <div class="text-xs text-gray-500">{{ upsStore.status.device.manufacturer }}</div>
      </div>
    </div>
  </div>
</template>
