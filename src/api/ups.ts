import axios from 'axios'
import type { UPSStatus, UPSVariable, UPSCommand } from '@/types/ups'

// Same-origin request to the CGI shipped by the package.
const api = axios.create({
  baseURL: '',
  timeout: 10000
})

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

export const upsApi = {
  async getStatus(upsName: string = 'ups'): Promise<UPSStatus> {
    try {
      const response = await api.get('/cgi-bin/ups-api.sh', {
        params: { ups: upsName }
      })
      return normalizeStatus(response.data)
    } catch (error) {
      if (import.meta.env.DEV) {
        console.warn('UPS API unreachable, using mock data', error)
        return mockData
      }
      throw new Error('无法连接 UPS 服务，请检查 NUT 是否运行、upsc 是否可用')
    }
  },

  async getVariables(_upsName: string = 'ups'): Promise<UPSVariable[]> {
    return []
  },

  async getCommands(_upsName: string = 'ups'): Promise<UPSCommand[]> {
    return []
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
