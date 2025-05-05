# postgres-vector-age
postgres16 with vector and age plugin


## 1.build docker image:  
   docker build -t postgres:16-v-a .  

## 2.run docker  
docker run --name pg16-v-a --restart=always \  
-e POSTGRES_PASSWORD=yourpwd \  
-e LANG=C.UTF-8 \  
-v /opt/pgdata:/var/lib/postgresql/data \  
-p 5432:5432 \  
-d localhost/postgres:16-v-a  
