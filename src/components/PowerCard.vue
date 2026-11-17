<script setup lang="ts">
import { computed } from 'vue'
import { useUPSStore } from '@/stores/ups'

const upsStore = useUPSStore()

const loadColor = computed(() => {
  if (!upsStore.status) return 'text-gray-400'
  const load = upsStore.status.output.load
  if (load < 50) return 'text-green-400'
  if (load < 80) return 'text-yellow-400'
  return 'text-red-400'
})
</script>

<template>
  <div class="stat-card">
    <div class="flex items-center justify-between mb-3">
      <h3 class="text-lg font-medium text-gray-300">电源信息</h3>
      <svg class="w-6 h-6 text-accent-orange" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
      </svg>
    </div>
    
    <div v-if="upsStore.status" class="space-y-4">
      <div>
        <div class="flex items-end justify-between mb-2">
          <span :class="['text-4xl font-bold', loadColor]">
            {{ upsStore.status.output.load }}%
          </span>
          <span class="text-sm text-gray-400">负载</span>
        </div>
        <div class="w-full bg-dark-bg h-3 rounded-full overflow-hidden">
          <div 
            :class="['h-full transition-all duration-500',
              upsStore.status.output.load < 50 ? 'bg-green-400' :
              upsStore.status.output.load < 80 ? 'bg-yellow-400' : 'bg-red-400'
            ]"
            :style="{ width: `${upsStore.status.output.load}%` }"
          />
        </div>
      </div>
      
      <div class="grid grid-cols-2 gap-3 pt-3 border-t border-dark-border">
        <div>
          <div class="text-xs text-gray-400 mb-1">输入电压</div>
          <div class="text-sm font-medium">{{ upsStore.status.input.voltage }} V</div>
        </div>
        <div>
          <div class="text-xs text-gray-400 mb-1">输出电压</div>
          <div class="text-sm font-medium">{{ upsStore.status.output.voltage }} V</div>
        </div>
        <div>
          <div class="text-xs text-gray-400 mb-1">频率</div>
          <div class="text-sm font-medium">{{ upsStore.status.output.frequency }} Hz</div>
        </div>
        <div>
          <div class="text-xs text-gray-400 mb-1">功率</div>
          <div class="text-sm font-medium">{{ upsStore.status.output.power }} W</div>
        </div>
      </div>
    </div>
    
    <div v-else class="text-center text-gray-400 py-8">
      <div class="animate-pulse">加载中...</div>
    </div>
  </div>
</template>
