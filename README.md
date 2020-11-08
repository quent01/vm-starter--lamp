# Vm-starter--lamp

## Introdution

Box build from [Scotchbox build scripts](https://github.com/scotch-io/scotch-box-build-scripts)

## Things installed

- Ubuntu 18.04
- PHP 7.2
- composer 2.0
- MySQL 5.7
- NGINX Option
- Go lang in the box
- PHPUnit in the box
- MailHog : launch command "mailhog" after vagrant ssh
- nodejs
- npm
- dos2unix : 
- shellcheck : 


## Todo

- choice of php version
- configurable web directory
- Pre install usefull php tools (for debugging for exemple phpcs, phpstan)

## Customize

- customise the scripts
- run ./shell/vendor/clean_box.sh 
- upload you change on vagrant with "vagrant cloud publish ..."

## Ressources
- [Scotchbox](https://github.com/scotch-io/scotch-box)
- [Scotchbox build scripts](https://github.com/scotch-io/scotch-box-build-scripts)