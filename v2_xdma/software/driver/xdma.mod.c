#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

MODULE_INFO(vermagic, VERMAGIC_STRING);

struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
 .name = KBUILD_MODNAME,
 .init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
 .exit = cleanup_module,
#endif
 .arch = MODULE_ARCH_INIT,
};

static const struct modversion_info ____versions[]
__used
__attribute__((section("__versions"))) = {
	{ 0x14522340, "module_layout" },
	{ 0x79fcc8d1, "device_remove_file" },
	{ 0x42e80c19, "cdev_del" },
	{ 0x4f1939c7, "per_cpu__current_task" },
	{ 0xc917223d, "pci_bus_read_config_byte" },
	{ 0x5a34a45c, "__kmalloc" },
	{ 0xc45a9f63, "cdev_init" },
	{ 0xc897c382, "sg_init_table" },
	{ 0xd6ee688f, "vmalloc" },
	{ 0xd2037915, "dev_set_drvdata" },
	{ 0xd8e484f0, "register_chrdev_region" },
	{ 0xc8b57c27, "autoremove_wake_function" },
	{ 0xd691cba2, "malloc_sizes" },
	{ 0xdd822018, "boot_cpu_data" },
	{ 0xa30682, "pci_disable_device" },
	{ 0xf417ff07, "pci_disable_msix" },
	{ 0x2bd43d13, "dynamic_debug_enabled2" },
	{ 0x2bb6fde2, "__kfifo_put" },
	{ 0x973873ab, "_spin_lock" },
	{ 0xa28e76e6, "schedule_work" },
	{ 0x640327fd, "__dynamic_pr_debug" },
	{ 0x7edc1537, "device_destroy" },
	{ 0x44b9fc43, "kobject_set_name" },
	{ 0x6729d3df, "__get_user_4" },
	{ 0x3fec048f, "sg_next" },
	{ 0xd3364703, "x86_dma_fallback_dev" },
	{ 0x102b9c3, "pci_release_regions" },
	{ 0x60038a0f, "aio_complete" },
	{ 0x7485e15e, "unregister_chrdev_region" },
	{ 0x999e8297, "vfree" },
	{ 0x712aa29b, "_spin_lock_irqsave" },
	{ 0x7d11c268, "jiffies" },
	{ 0x343a1a8, "__list_add" },
	{ 0xffc7c184, "__init_waitqueue_head" },
	{ 0x9629486a, "per_cpu__cpu_number" },
	{ 0xaf559063, "pci_set_master" },
	{ 0x9f1019bd, "pci_set_dma_mask" },
	{ 0x7b3d21a1, "pci_enable_msix" },
	{ 0x747f9a8e, "pci_iounmap" },
	{ 0x3da5eb6d, "kfifo_alloc" },
	{ 0xea147363, "printk" },
	{ 0xa1c76e0a, "_cond_resched" },
	{ 0x85f8a266, "copy_to_user" },
	{ 0xb4390f9a, "mcount" },
	{ 0x16305289, "warn_slowpath_null" },
	{ 0xb4ca9447, "__kfifo_get" },
	{ 0x521445b, "list_del" },
	{ 0x4b07e779, "_spin_unlock_irqrestore" },
	{ 0x2d2cf7d, "device_create" },
	{ 0x859c6dc7, "request_threaded_irq" },
	{ 0x520ee4c8, "pci_find_capability" },
	{ 0x7477dbc6, "device_create_file" },
	{ 0xa6d1bdca, "cdev_add" },
	{ 0x78764f4e, "pv_irq_ops" },
	{ 0xb2fd5ceb, "__put_user_4" },
	{ 0x108e8985, "param_get_uint" },
	{ 0x1000e51, "schedule" },
	{ 0x9cb480f4, "dynamic_debug_enabled" },
	{ 0x68f7c535, "pci_unregister_driver" },
	{ 0x2044fa9e, "kmem_cache_alloc_trace" },
	{ 0xe52947e7, "__phys_addr" },
	{ 0x642e54ac, "__wake_up" },
	{ 0x37a0cba, "kfree" },
	{ 0xc911f7f0, "remap_pfn_range" },
	{ 0xf59f2783, "dmam_alloc_noncoherent" },
	{ 0x6d090f30, "pci_request_regions" },
	{ 0x33d92f9a, "prepare_to_wait" },
	{ 0x94a8242d, "pci_disable_msi" },
	{ 0x3285cc48, "param_set_uint" },
	{ 0x5f07b9f3, "__pci_register_driver" },
	{ 0x72b295a3, "put_page" },
	{ 0xe06bb002, "class_destroy" },
	{ 0x9ccb2622, "finish_wait" },
	{ 0x9edbecae, "snprintf" },
	{ 0x6a7a886b, "pci_enable_msi_block" },
	{ 0x74ae34c9, "pci_iomap" },
	{ 0x66e992e3, "vmalloc_to_page" },
	{ 0x436c2179, "iowrite32" },
	{ 0xa12add91, "pci_enable_device" },
	{ 0xb02504d8, "pci_set_consistent_dma_mask" },
	{ 0xa2654165, "__class_create" },
	{ 0x3302b500, "copy_from_user" },
	{ 0xa92a43c, "dev_get_drvdata" },
	{ 0x6e9681d2, "dma_ops" },
	{ 0x29537c9e, "alloc_chrdev_region" },
	{ 0xe484e35f, "ioread32" },
	{ 0xa2046a95, "get_user_pages_fast" },
	{ 0x731184cd, "vm_insert_pfn" },
	{ 0xf20dabd8, "free_irq" },
	{ 0x15ef2dd9, "kfifo_free" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=";

MODULE_ALIAS("pci:v000032ABd00001333sv*sd*bc*sc*i*");

MODULE_INFO(srcversion, "F513765CAC2F81C88CC5CE0");

static const struct rheldata _rheldata __used
__attribute__((section(".rheldata"))) = {
	.rhel_major = 6,
	.rhel_minor = 8,
	.rhel_release = 641,
};
