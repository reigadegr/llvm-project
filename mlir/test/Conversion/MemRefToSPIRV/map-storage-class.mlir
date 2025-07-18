// RUN: mlir-opt -split-input-file -allow-unregistered-dialect -map-memref-spirv-storage-class='client-api=vulkan' -verify-diagnostics %s -o - | FileCheck %s --check-prefix=VULKAN
// RUN: mlir-opt -split-input-file -allow-unregistered-dialect -map-memref-spirv-storage-class='client-api=opencl' -verify-diagnostics %s -o - | FileCheck %s --check-prefix=OPENCL
// RUN: mlir-opt -split-input-file -allow-unregistered-dialect -map-memref-spirv-storage-class -verify-diagnostics %s -o - | FileCheck %s

// Vulkan Mappings:
//   0 -> StorageBuffer
//   1 -> Generic
//   2 -> [null]
//   3 -> Workgroup
//   4 -> Uniform
//   5 -> Private
//   6 -> Function
//   7 -> PushConstant
//   8 -> UniformConstant
//   9 -> Input
//   10 -> Output
//   11 -> PhysicalStorageBuffer
//   12 -> Image

// OpenCL Mappings:
//   0 -> CrossWorkgroup
//   1 -> Generic
//   2 -> [null]
//   3 -> Workgroup
//   4 -> UniformConstant
//   5 -> Private
//   6 -> Function
//   7 -> Image

// VULKAN-LABEL: func @operand_result
// OPENCL-LABEL: func @operand_result
func.func @operand_result() {
  // VULKAN: memref<f32, #spirv.storage_class<StorageBuffer>>
  // OPENCL: memref<f32, #spirv.storage_class<CrossWorkgroup>>
  %0 = "dialect.memref_producer"() : () -> (memref<f32>)
  // VULKAN: memref<4xi32, #spirv.storage_class<Generic>>
  // OPENCL: memref<4xi32, #spirv.storage_class<Generic>>
  %1 = "dialect.memref_producer"() : () -> (memref<4xi32, 1>)
  // VULKAN: memref<?x4xf16, #spirv.storage_class<Workgroup>>
  // OPENCL: memref<?x4xf16, #spirv.storage_class<Workgroup>>
  %2 = "dialect.memref_producer"() : () -> (memref<?x4xf16, 3>)
  // VULKAN: memref<*xf16, #spirv.storage_class<Uniform>>
  // OPENCL: memref<*xf16, #spirv.storage_class<UniformConstant>>
  %3 = "dialect.memref_producer"() : () -> (memref<*xf16, 4>)
  // VULKAN: memref<*xf16, #spirv.storage_class<Private>>
  // OPENCL: memref<*xf16, #spirv.storage_class<Private>>
  %4 = "dialect.memref_producer"() : () -> (memref<*xf16, 5>)
  // VULKAN: memref<*xf16, #spirv.storage_class<Function>>
  // OPENCL: memref<*xf16, #spirv.storage_class<Function>>
  %5 = "dialect.memref_producer"() : () -> (memref<*xf16, 6>)
  // VULKAN: memref<*xf16, #spirv.storage_class<PushConstant>>
  // OPENCL: memref<*xf16, #spirv.storage_class<Image>>
  %6 = "dialect.memref_producer"() : () -> (memref<*xf16, 7>)


  "dialect.memref_consumer"(%0) : (memref<f32>) -> ()
  // VULKAN: memref<4xi32, #spirv.storage_class<Generic>>
  // OPENCL: memref<4xi32, #spirv.storage_class<Generic>>
  "dialect.memref_consumer"(%1) : (memref<4xi32, 1>) -> ()
  // VULKAN: memref<?x4xf16, #spirv.storage_class<Workgroup>>
  // OPENCL: memref<?x4xf16, #spirv.storage_class<Workgroup>>
  "dialect.memref_consumer"(%2) : (memref<?x4xf16, 3>) -> ()
  // VULKAN: memref<*xf16, #spirv.storage_class<Uniform>>
  // OPENCL: memref<*xf16, #spirv.storage_class<UniformConstant>>
  "dialect.memref_consumer"(%3) : (memref<*xf16, 4>) -> ()
  // VULKAN: memref<*xf16, #spirv.storage_class<Private>>
  // OPENCL: memref<*xf16, #spirv.storage_class<Private>>
  "dialect.memref_consumer"(%4) : (memref<*xf16, 5>) -> ()
  // VULKAN: memref<*xf16, #spirv.storage_class<Function>>
  // OPENCL: memref<*xf16, #spirv.storage_class<Function>>
  "dialect.memref_consumer"(%5) : (memref<*xf16, 6>) -> ()
  // VULKAN: memref<*xf16, #spirv.storage_class<PushConstant>>
  // OPENCL: memref<*xf16, #spirv.storage_class<Image>>
  "dialect.memref_consumer"(%6) : (memref<*xf16, 7>) -> ()

  return
}

// -----

// VULKAN-LABEL: func @type_attribute
// OPENCL-LABEL: func @type_attribute
func.func @type_attribute() {
  // VULKAN: attr = memref<i32, #spirv.storage_class<Generic>>
  // OPENCL: attr = memref<i32, #spirv.storage_class<Generic>>
  "dialect.memref_producer"() { attr = memref<i32, 1> } : () -> ()
  return
}

// -----

// VULKAN-LABEL: func.func @function_io
// OPENCL-LABEL: func.func @function_io
func.func @function_io
  // VULKAN-SAME: (%{{.+}}: memref<f64, #spirv.storage_class<Generic>>, %{{.+}}: memref<4xi32, #spirv.storage_class<Workgroup>>)
  // OPENCL-SAME: (%{{.+}}: memref<f64, #spirv.storage_class<Generic>>, %{{.+}}: memref<4xi32, #spirv.storage_class<Workgroup>>)
  (%arg0: memref<f64, 1>, %arg1: memref<4xi32, 3>)
  // VULKAN-SAME: -> (memref<f64, #spirv.storage_class<Generic>>, memref<4xi32, #spirv.storage_class<Workgroup>>)
  // OPENCL-SAME: -> (memref<f64, #spirv.storage_class<Generic>>, memref<4xi32, #spirv.storage_class<Workgroup>>)
  -> (memref<f64, 1>, memref<4xi32, 3>) {
  return %arg0, %arg1: memref<f64, 1>, memref<4xi32, 3>
}

// -----

gpu.module @kernel {
// VULKAN-LABEL: gpu.func @function_io
// OPENCL-LABEL: gpu.func @function_io
// VULKAN-SAME: memref<8xi32, #spirv.storage_class<StorageBuffer>>
// OPENCL-SAME: memref<8xi32, #spirv.storage_class<CrossWorkgroup>>
gpu.func @function_io(%arg0 : memref<8xi32>) kernel { gpu.return }
}

// -----

// VULKAN-LABEL: func.func @region
// OPENCL-LABEL: func.func @region
func.func @region(%cond: i1, %arg0: memref<f32, 1>) {
  scf.if %cond {
    //      VULKAN: "dialect.memref_consumer"(%{{.+}}) {attr = memref<i64, #spirv.storage_class<Workgroup>>}
    //      OPENCL: "dialect.memref_consumer"(%{{.+}}) {attr = memref<i64, #spirv.storage_class<Workgroup>>}
    // VULKAN-SAME: (memref<f32, #spirv.storage_class<Generic>>) -> memref<f32, #spirv.storage_class<Generic>>
    // OPENCL-SAME: (memref<f32, #spirv.storage_class<Generic>>) -> memref<f32, #spirv.storage_class<Generic>>
    %0 = "dialect.memref_consumer"(%arg0) { attr = memref<i64, 3> } : (memref<f32, 1>) -> (memref<f32, 1>)
  }
  return
}

// -----

// VULKAN-LABEL: func @non_memref_types
// OPENCL-LABEL: func @non_memref_types
func.func @non_memref_types(%arg: f32) -> f32 {
  // VULKAN: "dialect.op"(%{{.+}}) {attr = 16 : i64} : (f32) -> f32
  // OPENCL: "dialect.op"(%{{.+}}) {attr = 16 : i64} : (f32) -> f32
  %0 = "dialect.op"(%arg) { attr = 16 } : (f32) -> (f32)
  return %0 : f32
}

// -----

func.func @missing_mapping() {
  // expected-error @+1 {{failed to legalize}}
  %0 = "dialect.memref_producer"() : () -> (memref<f32, 2>)
  return
}

// -----

/// Checks memory maps to OpenCL mapping if Kernel capability is enabled.
module attributes { spirv.target_env = #spirv.target_env<#spirv.vce<v1.0, [Kernel], []>, #spirv.resource_limits<>> } {
func.func @operand_result() {
  // CHECK: memref<f32, #spirv.storage_class<CrossWorkgroup>>
  %0 = "dialect.memref_producer"() : () -> (memref<f32>)
  // CHECK: memref<4xi32, #spirv.storage_class<Generic>>
  %1 = "dialect.memref_producer"() : () -> (memref<4xi32, 1>)
  // CHECK: memref<?x4xf16, #spirv.storage_class<Workgroup>>
  %2 = "dialect.memref_producer"() : () -> (memref<?x4xf16, 3>)
  // CHECK: memref<*xf16, #spirv.storage_class<UniformConstant>>
  %3 = "dialect.memref_producer"() : () -> (memref<*xf16, 4>)


  "dialect.memref_consumer"(%0) : (memref<f32>) -> ()
  // CHECK: memref<4xi32, #spirv.storage_class<Generic>>
  "dialect.memref_consumer"(%1) : (memref<4xi32, 1>) -> ()
  // CHECK: memref<?x4xf16, #spirv.storage_class<Workgroup>>
  "dialect.memref_consumer"(%2) : (memref<?x4xf16, 3>) -> ()
  // CHECK: memref<*xf16, #spirv.storage_class<UniformConstant>>
  "dialect.memref_consumer"(%3) : (memref<*xf16, 4>) -> ()

  return
}
}

// -----

/// Checks memory maps to Vulkan mapping if Shader capability is enabled.
module attributes { spirv.target_env = #spirv.target_env<#spirv.vce<v1.0, [Shader], []>, #spirv.resource_limits<>> } {
func.func @operand_result() {
  // CHECK: memref<f32, #spirv.storage_class<StorageBuffer>>
  %0 = "dialect.memref_producer"() : () -> (memref<f32>)
  // CHECK: memref<4xi32, #spirv.storage_class<Generic>>
  %1 = "dialect.memref_producer"() : () -> (memref<4xi32, 1>)
  // CHECK: memref<?x4xf16, #spirv.storage_class<Workgroup>>
  %2 = "dialect.memref_producer"() : () -> (memref<?x4xf16, 3>)
  // CHECK: memref<*xf16, #spirv.storage_class<Uniform>>
  %3 = "dialect.memref_producer"() : () -> (memref<*xf16, 4>)


  "dialect.memref_consumer"(%0) : (memref<f32>) -> ()
  // CHECK: memref<4xi32, #spirv.storage_class<Generic>>
  "dialect.memref_consumer"(%1) : (memref<4xi32, 1>) -> ()
  // CHECK: memref<?x4xf16, #spirv.storage_class<Workgroup>>
  "dialect.memref_consumer"(%2) : (memref<?x4xf16, 3>) -> ()
  // CHECK: memref<*xf16, #spirv.storage_class<Uniform>>
  "dialect.memref_consumer"(%3) : (memref<*xf16, 4>) -> ()
  return
}
}
