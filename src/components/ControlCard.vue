<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useUPSStore } from '@/stores/ups'
import { upsApi } from '@/api/ups'
import type { UPSCommand } from '@/types/ups'

const upsStore = useUPSStore()
const commands = ref<UPSCommand[]>([])
const loading = ref(false)
const executing = ref<string | null>(null)
const message = ref<{ type: 'success' | 'error'; text: string } | null>(null)

// 常用命令分类
const commonCommands = [
  { name: 'beeper.toggle', icon: '🔔', label: '切换蜂鸣器' },
  { name: 'test.battery.start.quick', icon: '⚡', label: '快速电池测试' },
  { name: 'test.battery.start', icon: '🔋', label: '完整电池测试' },
  { name: 'test.battery.stop', icon: '⏹️', label: '停止电池测试' }
]

onMounted(async () => {
  await loadCommands()
})

async function loadCommands() {
  try {
    loading.value = true
    const upsName = upsStore.status?.name || 'ups'
    commands.value = await upsApi.getCommands(upsName)
  } catch (error) {
    console.error('Failed to load commands:', error)
  } finally {
    loading.value = false
  }
}

async function executeCommand(commandName: string) {
  if (executing.value) return
  
  try {
    executing.value = commandName
    message.value = null
    
    const upsName = upsStore.status?.name || 'ups'
    const result = await upsApi.runCommand(upsName, commandName)
    
    if (result.success) {
      message.value = { type: 'success', text: result.message || '命令已执行' }
    } else {
      message.value = { type: 'error', text: result.error || '命令执行失败' }
    }
    
    // 3秒后清除提示
    setTimeout(() => {
      message.value = null
    }, 3000)
  } catch (error: any) {
    message.value = { type: 'error', text: error.message || '执行失败' }
    setTimeout(() => {
      message.value = null
    }, 3000)
  } finally {
    executing.value = null
  }
}

function getCommandInfo(name: string) {
  const common = commonCommands.find(c => c.name === name)
  if (common) return common
  
  const command = commands.value.find(c => c.name === name)
  return {
    name,
    icon: '⚙️',
    label: command?.description || name
  }
}

function isCommonCommand(name: string) {
  return commonCommands.some(c => c.name === name)
}
</script>

<template>
  <div class="card">
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-lg font-medium text-white">UPS 控制</h3>
      <button
        @click="loadCommands"
        :disabled="loading"
        class="text-sm text-gray-400 hover:text-white transition-colors"
      >
        {{ loading ? '加载中...' : '刷新' }}
      </button>
    </div>

    <!-- 消息提示 -->
    <div
      v-if="message"
      :class="[
        'mb-4 p-3 rounded-lg text-sm',
        message.type === 'success' 
          ? 'bg-green-500 bg-opacity-10 border border-green-500 text-green-400'
          : 'bg-red-500 bg-opacity-10 border border-red-500 text-red-400'
      ]"
    >
      {{ message.text }}
    </div>

    <!-- 常用命令 -->
    <div v-if="commands.length > 0" class="space-y-3">
      <div class="grid grid-cols-2 gap-3">
        <button
          v-for="cmd in commonCommands.filter(c => commands.some(x => x.name === c.name))"
          :key="cmd.name"
          @click="executeCommand(cmd.name)"
          :disabled="executing !== null"
          class="control-button"
        >
          <span class="text-2xl">{{ cmd.icon }}</span>
          <span class="text-sm">{{ cmd.label }}</span>
          <span v-if="executing === cmd.name" class="loading-spinner"></span>
        </button>
      </div>

      <!-- 其他命令 -->
      <details v-if="commands.some(c => !isCommonCommand(c.name))" class="mt-4">
        <summary class="cursor-pointer text-sm text-gray-400 hover:text-white">
          更多命令 ({{ commands.filter(c => !isCommonCommand(c.name)).length }})
        </summary>
        <div class="mt-3 space-y-2">
          <button
            v-for="cmd in commands.filter(c => !isCommonCommand(c.name))"
            :key="cmd.name"
            @click="executeCommand(cmd.name)"
            :disabled="executing !== null"
            class="w-full text-left px-3 py-2 rounded-lg bg-gray-800 hover:bg-gray-700 transition-colors text-sm"
          >
            <div class="font-medium text-white">{{ cmd.name }}</div>
            <div class="text-gray-400 text-xs mt-1">{{ cmd.description }}</div>
            <span v-if="executing === cmd.name" class="loading-spinner"></span>
          </button>
        </div>
      </details>
    </div>

    <!-- 加载状态 -->
    <div v-else-if="loading" class="text-center py-8 text-gray-400">
      加载命令列表...
    </div>

    <!-- 无命令 -->
    <div v-else class="text-center py-8 text-gray-400">
      暂无可用命令
    </div>
  </div>
</template>

<style scoped>
.control-button {
  @apply relative flex flex-col items-center gap-2 p-4 rounded-lg bg-gray-800 hover:bg-gray-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed;
}

.loading-spinner {
  @apply absolute top-2 right-2 w-4 h-4 border-2 border-gray-600 border-t-white rounded-full animate-spin;
}
</style>
