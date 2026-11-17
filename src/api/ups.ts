import axios from 'axios'
import type { UPSStatus, UPSVariable, UPSCommand } from '@/types/ups'

// Same-origin request to the LuCI-protected JSON endpoint.
const api = axios.create({
  baseURL: '',
  timeout: 10000,
  withCredentials: true
})

const API_URL = '/cgi-bin/luci/admin/services/ups-monitor/data'
const COMMANDS_URL = '/cgi-bin/luci/admin/services/ups-monitor/commands'
const RUN_COMMAND_URL = '/cgi-bin/luci/admin/services/ups-monitor/run-command'

// Development-only sample data, used when no router is reachable.
const mockData: UPSStatus = {
  name: 'ups',
  status: 'online',
  battery: {
    charge: 85,
    runtime: 1800,
    voltage: 13.5,
    temperature: 28
  },
  input: {
    voltage: 220,
    frequency: 50
  },
  output: {
    voltage: 220,
    frequency: 50,
    load: 35,
    power: 420
  },
  device: {
    manufacturer: 'APC',
    model: 'Smart-UPS 1500',
    type: 'ups'
  },
  lastUpdate: Date.now()
}

const mockCommands: UPSCommand[] = [
  { name: 'beeper.toggle', description: 'Toggle the UPS beeper' },
  { name: 'test.battery.start', description: 'Start a battery test' },
  { name: 'test.battery.start.quick', description: 'Start a quick battery test' },
  { name: 'test.battery.stop', description: 'Stop the battery test' }
]

export const upsApi = {
  async getStatus(upsName: string = 'ups'): Promise<UPSStatus> {
    try {
      const response = await api.get(API_URL, {
        params: { ups: upsName }
      })
      if (typeof response.data !== 'object' || response.data === null)
        throw new Error('UPS 接口未返回 JSON，请先登录 LuCI')
      return normalizeStatus(response.data)
    } catch (error) {
      if (import.meta.env.DEV) {
        console.warn('UPS API unreachable, using mock data', error)
        return mockData
      }
      throw new Error('无法连接 UPS 服务，请确认已登录 LuCI 且 NUT 正在运行')
    }
  },

  async getVariables(_upsName: string = 'ups'): Promise<UPSVariable[]> {
    return []
  },

  async getCommands(upsName: string = 'ups'): Promise<UPSCommand[]> {
    try {
      const response = await api.get(COMMANDS_URL, {
        params: { ups: upsName }
      })
      if (typeof response.data !== 'object' || !Array.isArray(response.data.commands))
        throw new Error('命令接口返回格式错误')
      return response.data.commands
    } catch (error) {
      if (import.meta.env.DEV) {
        console.warn('Commands API unreachable, using mock data', error)
        return mockCommands
      }
      throw new Error('无法获取 UPS 命令列表')
    }
  },

  async runCommand(upsName: string = 'ups', command: string): Promise<{ success: boolean; message?: string; error?: string }> {
    try {
      const response = await api.get(RUN_COMMAND_URL, {
        params: { ups: upsName, command }
      })
      if (typeof response.data !== 'object')
        throw new Error('命令执行接口返回格式错误')
      return response.data
    } catch (error) {
      if (import.meta.env.DEV) {
        console.warn('Run command API unreachable, simulating success', error)
        return { success: true, message: '命令已执行（模拟）' }
      }
      throw new Error('执行 UPS 命令失败')
    }
  }
}

function normalizeStatus(data: any): UPSStatus {
  const n = (value: unknown, fallback = 0): number => {
    const parsed = Number(value)
    return Number.isFinite(parsed) ? parsed : fallback
  }
  const status = ['online', 'onbatt', 'offline', 'unknown'].includes(data?.status)
    ? (data.status as UPSStatus['status'])
    : 'unknown'
  const temperature = Number(data?.battery?.temperature)

  return {
    name: String(data?.name ?? 'ups'),
    status,
    battery: {
      charge: n(data?.battery?.charge),
      runtime: n(data?.battery?.runtime),
      voltage: n(data?.battery?.voltage),
      temperature: Number.isFinite(temperature) ? temperature : undefined
    },
    input: {
      voltage: n(data?.input?.voltage),
      frequency: n(data?.input?.frequency)
    },
    output: {
      voltage: n(data?.output?.voltage),
      frequency: n(data?.output?.frequency),
      load: n(data?.output?.load),
      power: n(data?.output?.power)
    },
    device: {
      manufacturer: String(data?.device?.manufacturer ?? ''),
      model: String(data?.device?.model ?? ''),
      serial: data?.device?.serial ? String(data.device.serial) : undefined,
      type: data?.device?.type ? String(data.device.type) : 'ups'
    },
    lastUpdate: n(data?.lastUpdate, Date.now())
  }
}
