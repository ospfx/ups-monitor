<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { configApi } from '@/api/ups'

const loading = ref(false)
const saving = ref(false)
const detecting = ref(false)
const advancedMode = ref(false)
const message = ref<{ type: 'success' | 'error'; text: string } | null>(null)

const config = ref({
  drivers: [{ name: 'ups', enabled: true, driver: 'usbhid-ups', port: 'auto', desc: 'UPS Device' }],
  upsd: { enabled: true, listen_address: '127.0.0.1', listen_port: 3493 },
  users: [
    { name: 'admin', password: 'admin', actions: 'SET', instcmds: 'ALL', upsmon: '' },
    { name: 'monuser', password: 'monpass', actions: '', instcmds: '', upsmon: 'master' }
  ]
})

const availableDrivers = ref<any[]>([])
const detectedDevices = ref<any[]>([])

onMounted(async () => {
  await loadConfig()
  await loadDrivers()
})

async function loadConfig() {
  try {
    loading.value = true
    const data = await configApi.getConfig()
    if (data.drivers && data.drivers.length > 0) {
      config.value = data
    }
  } catch (error: any) {
    message.value = { type: 'error', text: error.message || '加载配置失败' }
  } finally {
    loading.value = false
  }
}

async function loadDrivers() {
  try {
    availableDrivers.value = await configApi.listDrivers()
  } catch (error) {
    console.error('Failed to load drivers:', error)
  }
}

async function detectDevices() {
  try {
    detecting.value = true
    message.value = null
    detectedDevices.value = await configApi.detectDevices()
    
    if (detectedDevices.value.length === 0) {
      message.value = { type: 'error', text: '未检测到 USB UPS 设备' }
    } else {
      message.value = { type: 'success', text: `检测到 ${detectedDevices.value.length} 个设备` }
    }
  } catch (error: any) {
    message.value = { type: 'error', text: error.message || '设备检测失败' }
  } finally {
    detecting.value = false
  }
}

async function saveConfig() {
  if (!confirm('确定要保存配置并重启 NUT 服务吗？这将中断当前的 UPS 监控。')) {
    return
  }
  
  try {
    saving.value = true
    message.value = null
    
    const result = await configApi.saveConfig(config.value)
    
    if (result.success) {
      message.value = { type: 'success', text: result.message || '配置已保存并重启服务' }
      // 延迟重新加载配置
      setTimeout(() => {
        loadConfig()
      }, 2000)
    } else {
      message.value = { type: 'error', text: result.error || '保存配置失败' }
    }
  } catch (error: any) {
    message.value = { type: 'error', text: error.message || '保存失败' }
  } finally {
    saving.value = false
  }
}

function applyDetectedDevice(device: any) {
  if (config.value.drivers.length === 0) {
    config.value.drivers.push({
      name: 'ups',
      enabled: true,
      driver: device.suggested_driver || 'usbhid-ups',
      port: 'auto',
      desc: device.name || 'UPS Device'
    })
  } else {
    config.value.drivers[0].driver = device.suggested_driver || 'usbhid-ups'
    config.value.drivers[0].desc = device.name || 'UPS Device'
  }
  
  message.value = { type: 'success', text: '已应用检测到的设备配置' }
  setTimeout(() => {
    message.value = null
  }, 3000)
}

const mainDriver = computed(() => {
  return config.value.drivers.length > 0 ? config.value.drivers[0] : null
})
</script>

<template>
  <div class="card">
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-lg font-medium text-white">NUT 配置</h3>
      <div class="flex gap-2">
        <button
          @click="advancedMode = !advancedMode"
          class="px-3 py-1 rounded text-sm bg-dark-border text-gray-400 hover:bg-gray-700 transition-colors"
        >
          {{ advancedMode ? '简单模式' : '高级模式' }}
        </button>
        <button
          @click="detectDevices"
          :disabled="detecting"
          class="px-3 py-1 rounded text-sm bg-accent-cyan text-dark-bg hover:bg-cyan-600 transition-colors disabled:opacity-50"
        >
          {{ detecting ? '检测中...' : '自动检测设备' }}
        </button>
      </div>
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

    <!-- 检测到的设备列表 -->
    <div v-if="detectedDevices.length > 0" class="mb-4 p-3 rounded-lg bg-dark-surface border border-dark-border">
      <div class="text-sm font-medium text-white mb-2">检测到的设备：</div>
      <div class="space-y-2">
        <div
          v-for="device in detectedDevices"
          :key="device.path"
          class="flex items-center justify-between p-2 rounded bg-gray-800"
        >
          <div class="text-sm">
            <div class="text-white font-medium">{{ device.name }}</div>
            <div class="text-gray-400 text-xs mt-1">
              {{ device.path }} ({{ device.vendor_id }}:{{ device.product_id }})
            </div>
            <div class="text-accent-cyan text-xs mt-1">
              建议驱动: {{ device.suggested_driver }}
            </div>
          </div>
          <button
            @click="applyDetectedDevice(device)"
            class="px-3 py-1 rounded text-xs bg-accent-cyan text-dark-bg hover:bg-cyan-600 transition-colors"
          >
            应用
          </button>
        </div>
      </div>
    </div>

    <div v-if="loading" class="text-center py-8 text-gray-400">
      加载配置中...
    </div>

    <div v-else class="space-y-4">
      <!-- 简单模式 -->
      <div v-if="!advancedMode && mainDriver" class="space-y-3">
        <div>
          <label class="block text-sm font-medium text-gray-300 mb-2">UPS 名称</label>
          <input
            v-model="mainDriver.name"
            type="text"
            class="w-full px-3 py-2 rounded-lg bg-gray-800 border border-gray-600 text-white focus:border-accent-cyan focus:outline-none"
            placeholder="ups"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-300 mb-2">驱动</label>
          <select
            v-model="mainDriver.driver"
            class="w-full px-3 py-2 rounded-lg bg-gray-800 border border-gray-600 text-white focus:border-accent-cyan focus:outline-none"
          >
            <option v-for="driver in availableDrivers" :key="driver.name" :value="driver.name">
              {{ driver.name }} - {{ driver.desc }}
            </option>
          </select>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-300 mb-2">USB 端口</label>
          <input
            v-model="mainDriver.port"
            type="text"
            class="w-full px-3 py-2 rounded-lg bg-gray-800 border border-gray-600 text-white focus:border-accent-cyan focus:outline-none"
            placeholder="auto"
          />
          <div class="text-xs text-gray-400 mt-1">通常使用 "auto" 自动检测</div>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-300 mb-2">描述</label>
          <input
            v-model="mainDriver.desc"
            type="text"
            class="w-full px-3 py-2 rounded-lg bg-gray-800 border border-gray-600 text-white focus:border-accent-cyan focus:outline-none"
            placeholder="UPS Device"
          />
        </div>
      </div>

      <!-- 高级模式 -->
      <div v-if="advancedMode" class="space-y-4">
        <!-- 驱动配置 -->
        <div class="p-3 rounded-lg bg-dark-surface border border-dark-border">
          <div class="text-sm font-medium text-white mb-3">驱动配置</div>
          <div v-for="(driver, index) in config.drivers" :key="index" class="space-y-3 mb-4">
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs text-gray-400 mb-1">名称</label>
                <input
                  v-model="driver.name"
                  type="text"
                  class="w-full px-2 py-1 rounded bg-gray-800 border border-gray-600 text-white text-sm"
                />
              </div>
              <div>
                <label class="block text-xs text-gray-400 mb-1">驱动</label>
                <select
                  v-model="driver.driver"
                  class="w-full px-2 py-1 rounded bg-gray-800 border border-gray-600 text-white text-sm"
                >
                  <option v-for="d in availableDrivers" :key="d.name" :value="d.name">
                    {{ d.name }}
                  </option>
                </select>
              </div>
              <div>
                <label class="block text-xs text-gray-400 mb-1">端口</label>
                <input
                  v-model="driver.port"
                  type="text"
                  class="w-full px-2 py-1 rounded bg-gray-800 border border-gray-600 text-white text-sm"
                />
              </div>
              <div>
                <label class="block text-xs text-gray-400 mb-1">描述</label>
                <input
                  v-model="driver.desc"
                  type="text"
                  class="w-full px-2 py-1 rounded bg-gray-800 border border-gray-600 text-white text-sm"
                />
              </div>
            </div>
            <div class="flex items-center">
              <input
                v-model="driver.enabled"
                type="checkbox"
                class="mr-2"
              />
              <span class="text-sm text-gray-400">启用此驱动</span>
            </div>
          </div>
        </div>

        <!-- upsd 配置 -->
        <div class="p-3 rounded-lg bg-dark-surface border border-dark-border">
          <div class="text-sm font-medium text-white mb-3">upsd 服务配置</div>
          <div class="space-y-3">
            <div class="flex items-center">
              <input
                v-model="config.upsd.enabled"
                type="checkbox"
                class="mr-2"
              />
              <span class="text-sm text-gray-400">启用 upsd 服务</span>
            </div>
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs text-gray-400 mb-1">监听地址</label>
                <input
                  v-model="config.upsd.listen_address"
                  type="text"
                  class="w-full px-2 py-1 rounded bg-gray-800 border border-gray-600 text-white text-sm"
                />
              </div>
              <div>
                <label class="block text-xs text-gray-400 mb-1">监听端口</label>
                <input
                  v-model.number="config.upsd.listen_port"
                  type="number"
                  class="w-full px-2 py-1 rounded bg-gray-800 border border-gray-600 text-white text-sm"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- 用户配置 -->
        <div class="p-3 rounded-lg bg-dark-surface border border-dark-border">
          <div class="text-sm font-medium text-white mb-3">用户配置</div>
          <div v-for="(user, index) in config.users" :key="index" class="space-y-2 mb-4">
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs text-gray-400 mb-1">用户名</label>
                <input
                  v-model="user.name"
                  type="text"
                  class="w-full px-2 py-1 rounded bg-gray-800 border border-gray-600 text-white text-sm"
                />
              </div>
              <div>
                <label class="block text-xs text-gray-400 mb-1">密码</label>
                <input
                  v-model="user.password"
                  type="password"
                  class="w-full px-2 py-1 rounded bg-gray-800 border border-gray-600 text-white text-sm"
                />
              </div>
              <div>
                <label class="block text-xs text-gray-400 mb-1">权限 (actions)</label>
                <input
                  v-model="user.actions"
                  type="text"
                  class="w-full px-2 py-1 rounded bg-gray-800 border border-gray-600 text-white text-sm"
                  placeholder="SET"
                />
              </div>
              <div>
                <label class="block text-xs text-gray-400 mb-1">命令权限 (instcmds)</label>
                <input
                  v-model="user.instcmds"
                  type="text"
                  class="w-full px-2 py-1 rounded bg-gray-800 border border-gray-600 text-white text-sm"
                  placeholder="ALL"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 保存按钮 -->
      <div class="flex justify-end pt-4 border-t border-dark-border">
        <button
          @click="saveConfig"
          :disabled="saving"
          class="px-6 py-2 rounded-lg bg-accent-cyan text-dark-bg font-medium hover:bg-cyan-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {{ saving ? '保存中...' : '保存并重启服务' }}
        </button>
      </div>
    </div>
  </div>
</template>
