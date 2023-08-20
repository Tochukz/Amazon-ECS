# Laravel App
__Description__ 
Sample Laravel application supported by Docker container

## Setup 
__Run local development server__ 
```
$ php artisan serve
```
__Run docker container__   
Build the docker image 
```bash 
$ docker build -t bbdchucks/laravel-app .
```
Run a container 
```bash 
$ docker run -d -p 80:80 --name your-laravel-container your-laravel-app
```  

__Package the application code__  
```bash
$ zip -r laravel-app.zip laravel-app -x "laravel-app/vendor/*"
```