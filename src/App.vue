<script setup lang="ts">
import { RouterView } from 'vue-router'
</script>

<template>
  <div class="min-h-screen bg-dark-bg">
    <header class="border-b border-dark-border bg-dark-surface">
      <div class="container mx-auto px-4 py-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 bg-accent-cyan rounded-lg flex items-center justify-center">
              <svg class="w-5 h-5 text-dark-bg" fill="currentColor" viewBox="0 0 20 20">
                <path d="M11 3a1 1 0 10-2 0v1a1 1 0 102 0V3zM15.657 5.757a1 1 0 00-1.414-1.414l-.707.707a1 1 0 001.414 1.414l.707-.707zM18 10a1 1 0 01-1 1h-1a1 1 0 110-2h1a1 1 0 011 1zM5.05 6.464A1 1 0 106.464 5.05l-.707-.707a1 1 0 00-1.414 1.414l.707.707zM5 10a1 1 0 01-1 1H3a1 1 0 110-2h1a1 1 0 011 1zM8 16v-1h4v1a2 2 0 11-4 0zM12 14c.015-.34.208-.646.477-.859a4 4 0 10-4.954 0c.27.213.462.519.476.859h4.002z"/>
              </svg>
            </div>
            <h1 class="text-xl font-semibold">UPS Monitor</h1>
          </div>
          <div class="flex items-center gap-2 text-sm">
            <span class="text-gray-400">路由器 UPS 管理</span>
          </div>
        </div>
      </div>
    </header>
    
    <main class="container mx-auto px-4 py-6">
      <RouterView />
    </main>
  </div>
</template>
