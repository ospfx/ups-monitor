<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, GaugeChart } from 'echarts/charts'
import { GridComponent, TooltipComponent, LegendComponent } from 'echarts/components'
import VChart from 'vue-echarts'
import { useUPSStore } from '@/stores/ups'

use([CanvasRenderer, LineChart, GaugeChart, GridComponent, TooltipComponent, LegendComponent])

const upsStore = useUPSStore()

const historyData = ref<{
  time: string[]
  voltage: number[]
  load: number[]
  battery: number[]
}>({
  time: [],
  voltage: [],
  load: [],
  battery: []
})

watch(() => upsStore.status, (newStatus) => {
  if (!newStatus) return
  
  const now = new Date().toLocaleTimeString()
  historyData.value.time.push(now)
  historyData.value.voltage.push(newStatus.input.voltage)
  historyData.value.load.push(newStatus.output.load)
  historyData.value.battery.push(newStatus.battery.charge)
  
  if (historyData.value.time.length > 60) {
    historyData.value.time.shift()
    historyData.value.voltage.shift()
    historyData.value.load.shift()
    historyData.value.battery.shift()
  }
})

const chartOption = computed(() => ({
  backgroundColor: 'transparent',
  tooltip: {
    trigger: 'axis',
    backgroundColor: '#1E293B',
    borderColor: '#334155',
    textStyle: { color: '#F8FAFC' }
  },
  legend: {
    data: ['电池电量', '负载', '输入电压'],
    textStyle: { color: '#F8FAFC' },
    top: 10
  },
  grid: {
    left: '3%',
    right: '4%',
    bottom: '3%',
    top: 50,
    containLabel: true
  },
  xAxis: {
    type: 'category',
    data: historyData.value.time,
    axisLine: { lineStyle: { color: '#334155' } },
    axisLabel: { color: '#94A3B8' }
  },
  yAxis: [
    {
      type: 'value',
      name: '百分比 (%)',
      position: 'left',
      axisLine: { lineStyle: { color: '#334155' } },
      axisLabel: { color: '#94A3B8' },
      splitLine: { lineStyle: { color: '#334155', type: 'dashed' } }
    },
    {
      type: 'value',
      name: '电压 (V)',
      position: 'right',
      axisLine: { lineStyle: { color: '#334155' } },
      axisLabel: { color: '#94A3B8' },
      splitLine: { show: false }
    }
  ],
  series: [
    {
      name: '电池电量',
      type: 'line',
      data: historyData.value.battery,
      smooth: true,
      itemStyle: { color: '#22D3EE' },
      areaStyle: {
        color: {
          type: 'linear',
          x: 0, y: 0, x2: 0, y2: 1,
          colorStops: [
            { offset: 0, color: 'rgba(34, 211, 238, 0.3)' },
            { offset: 1, color: 'rgba(34, 211, 238, 0)' }
          ]
        }
      }
    },
    {
      name: '负载',
      type: 'line',
      data: historyData.value.load,
      smooth: true,
      itemStyle: { color: '#F97316' }
    },
    {
      name: '输入电压',
      type: 'line',
      yAxisIndex: 1,
      data: historyData.value.voltage,
      smooth: true,
      itemStyle: { color: '#38BDF8' }
    }
  ]
}))
</script>

<template>
  <div class="card">
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-lg font-medium text-gray-300">实时监控</h3>
      <button 
        @click="upsStore.toggleAutoRefresh()"
        :class="['px-3 py-1 rounded text-sm transition-colors',
          upsStore.autoRefresh 
            ? 'bg-accent-cyan text-dark-bg' 
            : 'bg-dark-border text-gray-400'
        ]"
      >
        {{ upsStore.autoRefresh ? '自动刷新' : '已暂停' }}
      </button>
    </div>
    
    <div v-if="historyData.time.length > 0" class="h-80">
      <v-chart :option="chartOption" class="w-full h-full" autoresize />
    </div>
    
    <div v-else class="h-80 flex items-center justify-center text-gray-400">
      等待数据...</div>
  </div>
</template>
