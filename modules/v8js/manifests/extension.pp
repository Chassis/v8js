# A class to setup the v8js extension and dependencies.
class v8js::extension(
	$config
) {
	if ( ! empty( $config[disabled_extensions] ) and 'chassis/v8js' in $config[disabled_extensions] ) {
		$package = absent
	} else {
		$package = installed
	}

	$lib_v8_version = $config['libv8']
	$v8js_version   = $config['v8js']
	apt::ppa { 'ppa:stesie/libv8':
		require => Class['apt'],
	}

	package { [ "libv8-${lib_v8_version}", "libv8-${lib_v8_version}-dev", 're2c' ]:
		ensure  => $package,
		require => [ Apt::Ppa['ppa:stesie/libv8'] ],
	}

	$version = $config[php]

	if $version =~ /^(\d+)\.(\d+)$/ {
		$package_version = "${version}.*"
		$short_ver = $version
	}
	else {
		$package_version = "${version}*"
		$short_ver = regsubst($version, '^(\d+\.\d+)\.\d+$', '\1')
	}

	if versioncmp( $version, '5.4') <= 0 {
		$php_package = 'php5'
	}
	else {
		$php_package = "php${version}"
	}

	ensure_packages( [ "${php_package}-dev" ], {
		ensure  => $package,
		require => [
			Apt::Ppa['ppa:ondrej/php'],
			Class['apt::update'],
		],
	} )

	ensure_packages( [ 'php-pear' ], {
		ensure  => latest,
		require => [
			Package["${php_package}-dev"],
			Package["${php_package}-xml"],
		],
	} )

	ensure_resource( 'exec', 'pecl channel-update pecl.php.net', {
		path    => '/usr/bin',
		require => [
			Package['php-pear'],
			Package["${php_package}-dev"],
			Package["${php_package}-xml"],
		],
	} )

	if versioncmp( $version, '7.2' ) >= 0 {
		exec { 'install archive tar':
			path    => '/usr/bin',
			command => 'pear install Archive_Tar',
			require => [
				Package['php-pear'],
				Package["${php_package}-xml"],
			],
			unless  => 'pear info Archive_Tar',
		}
	}

	if ( installed == $package ) {
		exec { 'pecl install v8js':
			command => "/bin/echo '/opt/libv8-${lib_v8_version}
				' | /usr/bin/pecl install v8js-${v8js_version}",
			unless  => "/usr/bin/pecl info v8js | grep ${v8js_version}",
			require => [
				Package["libv8-${lib_v8_version}"],
				Package["libv8-${lib_v8_version}-dev"],
				Package['php-pear'],
				Package["${php_package}-dev"],
				Package["${php_package}-fpm"],
				Exec['pecl channel-update pecl.php.net'],
			],
		}

		file { "/etc/php/${version}/mods-available/v8js.ini":
			ensure  => file,
			content => 'extension=v8js.so',
			require => Exec['pecl install v8js'],
		}

		file { [
			"/etc/php/${version}/fpm/conf.d/99-v8js.ini",
			"/etc/php/${version}/cli/conf.d/99-v8js.ini"
		]:
			ensure  => link,
			require => [
				File["/etc/php/${version}/mods-available/v8js.ini"],
				Package["${php_package}-fpm"],
			],
			target  => "/etc/php/${version}/mods-available/v8js.ini",
			notify  => Service["${php_package}-fpm"],
		}
	} else {
		exec { 'pecl uninstall v8js':
			path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
			command => 'pecl uninstall v8js',
			require => Package['php-pear'],
		}
		file { [
			"/etc/php/${version}/mods-available/v8js.ini",
			"/etc/php/${version}/fpm/conf.d/99-v8js.ini",
			"/etc/php/${version}/cli/conf.d/99-v8js.ini"
		]:
			ensure => absent,
			notify => Service["${php_package}-fpm"],
		}
	}
}
