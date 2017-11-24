docker run -it --name pg --link me:postgres --network=host -p 5432:5432 postgres:9.4 psql -h postgres -U postgres
