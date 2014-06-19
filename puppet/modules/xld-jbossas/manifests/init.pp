# == Class: baseconfig
#
# Install JBossAS instance and declare it in XLD
#


class xld-jbossas {

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

  include java
  include jbossas

  deployit { "xld-jbossas":
    username             => "admin",
    password             => "admin",
    url                  => "http://10.0.2.2:4516",
    encrypted_dictionary => "Environments/$environment/PuppetModuleDictionary"
  }

  deployit_directory { "Infrastructure/$environment":
    server   	  => Deployit["xld-jbossas"],
  }

  deployit_directory { "Environments/$environment":
    server   	  => Deployit["xld-jbossas"],
    require    => Deployit_directory["Infrastructure/$environment"]
  }

  deployit_container { "Infrastructure/$environment/$fqdn":
    type     	  => "overthere.SshHost",
    properties	=> {
      os      => UNIX,
      address => $ipaddress_eth1,
      username  => vagrant,
      password => vagrant,
      connectionType => INTERACTIVE_SUDO,
      sudoUsername => jbossas,
    },
    server   	 => Deployit["xld-jbossas"],
    require    => Deployit_directory["Infrastructure/$environment"]
  }

  deployit_container { "Infrastructure/$environment/$fqdn/$hostname":
    type     	=> 'jbossas.ServerV5',
    properties	=> {
      home 			  => hiera('jbossas::home'),
      serverName 	=> hiera('jbossas::configuration'),
    },
    server   	   => Deployit["xld-jbossas"],
    require 	   => Deployit_container["Infrastructure/$environment/$fqdn"],
    environments => "Environments/$environment/App-$environment",
  }

  deployit_dictionary {"Environments/$environment/App-$environment-$hostname.dict":
    server   	   => Deployit["xld-jbossas"],
    environments => "Environments/$environment/App-$environment",
    require 	   => Deployit_container["Infrastructure/$environment/$fqdn/$hostname"],
    entries      => {
      'TITLE'    => "Hello from {{IP}}",
      'IP'       => $ipaddress_eth1,
    },
    restrict_to_containers => ["Infrastructure/$environment/$fqdn/$hostname"],
  }


}
