# == Class: baseconfig
#
# Install Tomcat instance and declare it in XLD
#


class xld-tomcat {
  class { 'tomcat':
    version    => "7",
    sources    => true,
    sources_src => "file:/catalog/Tomcat"
  }

  tomcat::instance {'appserver':
    ensure      => present,
    server_port => hiera('tomcat.port.mgt'),
    http_port   => hiera('tomcat.port.http'),
    ajp_port    => hiera('tomcat.port.ajp'),
  }

  deployit_container { "Infrastructure/$environment/$fqdn/appserver-$hostname":
    type     	      => 'tomcat.Server',
    properties      => {
      stopCommand   => '/etc/init.d/tomcat-appserver stop',
      startCommand  => 'nohup /etc/init.d/tomcat-appserver start',
      home          => '/srv/tomcat/appserver',
      stopWaitTime	=> 0,
      startWaitTime => 10,
    },
    server   	=> Deployit["xld-server"],
    require 	=> Deployit_container["Infrastructure/$environment/$fqdn"],
    environments => "Environments/$environment/App-$environment",
  }

  deployit_container { "Infrastructure/$environment/$fqdn/appserver-$hostname/$hostname.vh":
    type     	=> 'tomcat.VirtualHost',
    properties	=> { },
    server   	=> Deployit["xld-server"],
    require 	=> Deployit_container["Infrastructure/$environment/$fqdn/appserver-$hostname"],
    environments => "Environments/$environment/App-$environment",
  }

  deployit_container { "Infrastructure/$environment/$fqdn/test-runner-$hostname":
    type     	=> 'tests2.TestRunner',
    properties	=> { },
    server   	=> Deployit["xld-server"],
    require 	=> [Deployit_container["Infrastructure/$environment/$fqdn"],Deployit_container["Infrastructure/$environment/$fqdn/appserver-$hostname/$hostname.vh"]],
    environments => "Environments/$environment/App-$environment",
  }

  deployit_dictionary { "Environments/$environment/$fqdn.dict":
    entries                                                 => {
      "log.RootLevel"                                       => "ERROR",
      "log.FilePath"                                        => "/tmp/null",
      "tomcat.port"                                         =>  hiera('tomcat.port.http'),
      "tests2.ExecutedHttpRequestTest.url"                  => "http://localhost:{{tomcat.port}}/petclinic/index.jsp",
      "tomcat.DataSource.username"                          => "scott",
      "tomcat.DataSource.password"                          => "tiger",
      "TITLE"                                               => "$environment",
      "tomcat.DataSource.driverClassName"                   => "com.mysql.jdbc.Driver",
      "tomcat.DataSource.url"                               => "jdbc:mysql://localhost/{{tomcat.DataSource.context}}",
      "tomcat.DataSource.context"                           => "petclinic",
      "tests2.ExecutedHttpRequestTest.expectedResponseText" => "Home",
    },
    restrict_to_containers => ["Infrastructure/$environment/$fqdn/appserver-$hostname/$hostname.vh", "Infrastructure/$environment/$fqdn/test-runner-$hostname", "Infrastructure/$environment/$fqdn/appserver-$hostname"],
    environments         => "Environments/$environment/App-$environment",
    server   	           => Deployit["xld-server"],
    require              => Deployit_container["Infrastructure/$environment/$fqdn/test-runner-$hostname"]
  }

}
