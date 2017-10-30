you might want to install latencytop from sources and not use the one from Ubuntu repository:

this comes from the latencytop, which comes with Ubuntu:

Jul  6 10:07:17 X61s-2 kernel: [ 1795.077586] ------------[ cut here ]------------
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077609] WARNING: at kernel/trace/trace.c:2725 tracing_ctrl_write+0xd2/0x14a()
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077617] Hardware name: 7667CB5
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077622] tracing_enabled is deprecated. Use tracing_on
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077629] Modules linked in: fuse snd_hda_codec_analog snd_hda_intel snd_hda_codec snd_pcm_oss snd_mixer_oss snd_pcm thinkpad_acpi snd_seq_oss snd_seq_midi snd_rawmidi snd_seq_midi_event i915 drm_kms_helper snd_seq snd_timer snd_seq_device drm i2c_algo_bit nvram snd i2c_core intel_agp video backlight intel_gtt snd_page_alloc ext4 jbd2 crc16 ata_generic ahci ata_piix libahci ehci_hcd uhci_hcd e1000e [last unloaded: my_debugfs]
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077760] Pid: 10914, comm: latencytop Not tainted 2.6.39-lf320-debug-00001-g62028ed-dirty #1
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077768] Call Trace:
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077782]  [<ffffffff8103fa08>] warn_slowpath_common+0x85/0x9d
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077794]  [<ffffffff8103fac3>] warn_slowpath_fmt+0x46/0x48
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077806]  [<ffffffff810a6d77>] ? tracing_ctrl_write+0xa2/0x14a
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077816]  [<ffffffff810a6da7>] tracing_ctrl_write+0xd2/0x14a
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077829]  [<ffffffff810f8e82>] vfs_write+0xb2/0x12e
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077839]  [<ffffffff810f90e4>] sys_write+0x4a/0x71
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077852]  [<ffffffff81379aeb>] system_call_fastpath+0x16/0x1b
Jul  6 10:07:17 X61s-2 kernel: [ 1795.077861] ---[ end trace 3cc6eb26e6905a69 ]---


