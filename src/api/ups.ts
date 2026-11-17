import axios from 'axios'
import type { UPSStatus, UPSVariable, UPSCommand } from '@/types/ups'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000
})

// 模拟数据（用于开发测试）
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
    serial: 'AS1234567890',
    type: 'ups'
  },
  lastUpdate: Date.now()
}

export const upsApi = {
  // 获取UPS状态
  async getStatus(upsName: string = 'ups'): Promise<UPSStatus> {
    try {
      // 实际环境中调用NUT CGI或自定义接口
      const response = await api.get(`/cgi-bin/nut/upsstats.cgi?host=${upsName}`)
      return parseUPSStatus(response.data)
    } catch (error) {
      console.warn('使用模拟数据', error)
      // 开发环境返回模拟数据
      return mockData
    }
  },

  // 获取所有变量
  async getVariables(upsName: string = 'ups'): Promise<UPSVariable[]> {
    try {
      const response = await api.get(`/cgi-bin/nut/upsvar.cgi?host=${upsName}`)
      return parseVariables(response.data)
    } catch (error) {
      console.warn('获取变量失败', error)
      return []
    }
  },

  // 获取可用命令
  async getCommands(upsName: string = 'ups'): Promise<UPSCommand[]> {
    try {
      const response = await api.get(`/cgi-bin/nut/upscmd.cgi?host=${upsName}`)
      return parseCommands(response.data)
    } catch (error) {
      console.warn('获取命令失败', error)
      return []
    }
  },

  // 执行UPS命令
  async executeCommand(upsName: string, command: string, username?: string, password?: string): Promise<boolean> {
    try {
      await api.post(`/cgi-bin/nut/upscmd.cgi`, {
        host: upsName,
        cmd: command,
        username,
        password
      })
      return true
    } catch (error) {
      console.error('命令执行失败', error)
      return false
    }
  }
}

// 解析NUT数据格式（需根据实际CGI输出调整）
function parseUPSStatus(data: any): UPSStatus {
  // 这里需要根据实际的upsstats.cgi输出格式解析
  // 示例假设返回JSON格式
  return data
}

function parseVariables(data: any): UPSVariable[] {
  return []
}

function parseCommands(data: any): UPSCommand[] {
  return []
}
