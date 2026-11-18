<script setup lang="ts">
import ConfigCard from '@/components/ConfigCard.vue'
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h2 class="text-2xl font-bold text-white">NUT 配置</h2>
      <a
        href="/ups/"
        class="px-4 py-2 rounded-lg bg-dark-border text-gray-300 hover:bg-gray-700 transition-colors"
      >
        返回监控页面
      </a>
    </div>
    
    <ConfigCard />
  </div>
</template>
