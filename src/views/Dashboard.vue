<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useUPSStore } from '@/stores/ups'
import StatusCard from '@/components/StatusCard.vue'
import BatteryCard from '@/components/BatteryCard.vue'
import PowerCard from '@/components/PowerCard.vue'
import ChartCard from '@/components/ChartCard.vue'
import ControlCard from '@/components/ControlCard.vue'
import ConfigCard from '@/components/ConfigCard.vue'

const upsStore = useUPSStore()
const activeTab = ref<'monitor' | 'config'>('monitor')

// Check if embedded in LuCI
const isEmbedded = new URLSearchParams(window.location.search).has('embed')

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
    <!-- 标签页切换 -->
    <div class="flex gap-2 border-b border-dark-border">
      <button
        @click="activeTab = 'monitor'"
        :class="[
          'px-4 py-2 font-medium transition-colors',
          activeTab === 'monitor'
            ? 'text-accent-cyan border-b-2 border-accent-cyan'
            : 'text-gray-400 hover:text-gray-300'
        ]"
      >
        📊 实时监控
      </button>
      <button
        @click="activeTab = 'config'"
        :class="[
          'px-4 py-2 font-medium transition-colors',
          activeTab === 'config'
            ? 'text-accent-cyan border-b-2 border-accent-cyan'
            : 'text-gray-400 hover:text-gray-300'
        ]"
      >
        ⚙️ NUT 配置
      </button>
    </div>

    <!-- 监控标签页 -->
    <div v-if="activeTab === 'monitor'" class="space-y-6">
      <StatusCard />
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <BatteryCard />
        <PowerCard />
      </div>
      
      <ChartCard />
      
      <ControlCard />
    </div>

    <!-- 配置标签页 -->
    <div v-if="activeTab === 'config'" class="space-y-6">
      <ConfigCard />
    </div>

    <!-- 错误提示 -->
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
