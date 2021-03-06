#
# Usage
#   swift::storage::mount
#
#
define swift::storage::mount(
  $device,
  $mnt_base_dir = '/srv/node',
  $loopback     = false,
  $fstype       = 'xfs'
) {

  if($loopback){
    $options = 'noatime,nodiratime,nobarrier,loop'
  } else {
    $options = 'noatime,nodiratime,nobarrier'
  }

  if($fstype == 'xfs'){
     $fsoptions = 'logbufs=8'
  } else {
     $fsoptions = 'user_xattr'
  }

  # the directory that represents the mount point
  # needs to exist
  file { "${mnt_base_dir}/${name}":
    ensure => directory,
    owner  => 'swift',
    group  => 'swift',
  }

  mount { "${mnt_base_dir}/${name}":
    ensure  => present,
    device  => $device,
    fstype  => $fstype,
    options => "$options,$fsoptions",
    require => File["${mnt_base_dir}/${name}"]
  }

  # double checks to make sure that things are mounted
  exec { "mount_${name}":
    command   => "mount ${mnt_base_dir}/${name}",
    path      => ['/bin'],
    require   => Mount["${mnt_base_dir}/${name}"],
    unless    => "grep ${mnt_base_dir}/${name} /etc/mtab",
    # TODO - this needs to be removed when I am done testing
    logoutput => true,
  }

  exec { "fix_mount_permissions_${name}":
    command     => "chown -R swift:swift ${mnt_base_dir}/${name}",
    path        => ['/usr/sbin', '/bin'],
    subscribe   => Exec["mount_${name}"],
    refreshonly => true,
  }
}
