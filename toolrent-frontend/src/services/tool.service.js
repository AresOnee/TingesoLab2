// src/services/tool.service.js
import http from '../http-common'

const getAll = async () => {
  const { data } = await http.get('/api/v1/tools')
  return Array.isArray(data) ? data : (data?.content ?? [])
}

/**
 * RF1.1: Crear nueva herramienta
 * Envía X-Username para registrar en Kardex quién creó la herramienta
 */
const create = (body, username) => {
  return http.post('/api/v1/tools', body, {
    headers: {
      'X-Username': username || 'system'
    }
  })
}

/**
 * RF1.2: Dar de baja herramientas (solo Admin)
 * PUT /api/v1/tools/{id}/decommission
 * Envía X-Username para registrar en Kardex quién dio de baja
 */
const decommission = async (toolId, username) => {
  const { data } = await http.put(`/api/v1/tools/${toolId}/decommission`, null, {
    headers: {
      'X-Username': username || 'system'
    }
  })
  return data
}

const toolService = {
  getAll,
  create,
  decommission,
}

export default toolService
