### Commands to start / stop sql server


```
PS C:\Users\parag\OneDrive\Documents\Parag\Development\Docker\sqlServer> docker-compose up -d
[+] Running 2/2
 ✔ Network ms-sql-server_default     Created                                                                                                                                                               0.1s 
 ✔ Container 2022-CU17-ubuntu-22.04  Started        

====================

PS C:\Users\parag\OneDrive\Documents\Parag\Development\Docker\sqlServer> docker-compose down    
[+] Running 2/2
 ✔ Container 2022-CU17-ubuntu-22.04  Removed                                                                                                                                                               1.7s 
 ✔ Network ms-sql-server_default     Removed   

```


### Connect to MS Sql server

Use below details in SSMS (SQL server management studio)  

**Database**: localhost  
**User**: sa  
**Password**: Pick from docker file  
**Trust Server Certificate**: True  


### Docker commands for python build / run

```
docker build -t parag.majithia/sqlserver-iceberg-demo:latest .

docker run parag.majithia/sqlserver-iceberg-demo:latest

```