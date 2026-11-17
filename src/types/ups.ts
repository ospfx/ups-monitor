export interface UPSStatus {
  name: string
  status: 'online' | 'onbatt' | 'offline' | 'unknown'
  battery: {
    charge: number
    runtime: number
    voltage: number
    temperature?: number
  }
  input: {
    voltage: number
    frequency: number
  }
  output: {
    voltage: number
    frequency: number
    load: number
    power: number
  }
  device: {
    manufacturer: string
    model: string
    serial?: string
    type?: string
  }
  lastUpdate: number
}

export interface UPSVariable {
  name: string
  value: string
  description?: string
}

export interface UPSCommand {
  name: string
  description: string
}
