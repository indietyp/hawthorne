# Docker Image
!> Introduced in v0.7.2

The docker image is an easy and more effortless way to deploy hawthorne. If you are not familiar with containerisation or Docker itself, please refer to the official [Docker documentation][1]. **We will not go further into the specifics of Docker in itself.**

For your convenience a docker-compose file has been provided for you. In `cli/configs/docker-compose.default.yml`. The docker-compose.yml file is included in the **.gitignore**, so do not worry using that, if you want to clone the repo. You do not need to do so tho.

To use the Docker image just `docker pull indietyp/hawthorne ` to receive the image. The unicorn WSGI server is being served on port 8000 (_Note:_ It is not served with a socket, because of several problems regarding Docker in itself.)

# Parameters
Several Docker environment variables need to be supplied, so that the service can run smoothly.

| Variable        | Example        | Syntax            | Description |
| ------------ |:---:|:---:| ---:|
| `DOMAIN` | localhost | — | IP or domain where hawthorne will be served |
| `DB` | root:123456@localhost:3307/hawthorne | &lt;user&gt;: &lt; password&gt;@ &lt;host&gt;: &lt;port&gt;/&lt;database&gt; | database connection scheme |
| `API` | 74BAE66A95B0AB6E9E4443EB232E1D63 | — | Steam provided API key |
| `ADMIN` | 76561198056522927 | — | SteamID64 of the superuser (**probably yours**)

[1]:	https://docs.docker.com/get-started/