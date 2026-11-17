<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue'
import { useUPSStore } from '@/stores/ups'
import StatusCard from '@/components/StatusCard.vue'
import BatteryCard from '@/components/BatteryCard.vue'
import PowerCard from '@/components/PowerCard.vue'
import ChartCard from '@/components/ChartCard.vue'
import ControlCard from '@/components/ControlCard.vue'

const upsStore = useUPSStore()

onMounted(() => {
  const upsName = new URLSearchParams(window.location.search).get('ups') || 'ups'
  upsStore.startAutoRefresh(upsName)
})

onUnmounted(() => {
  upsStore.stopAutoRefresh()
})
</script>

<template>
  <div class="space-y-6">
    <StatusCard />
    
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <BatteryCard />
      <PowerCard />
    </div>
    
    <ChartCard />
    
    <ControlCard />
    
    <div v-if="upsStore.error" class="card bg-red-500 bg-opacity-10 border-red-500">
      <div class="flex items-center gap-3">
        <svg class="w-5 h-5 text-red-400" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
        </svg>
        <span class="text-red-400">{{ upsStore.error }}</span>
      </div>
    </div>
  </div>
</template>
