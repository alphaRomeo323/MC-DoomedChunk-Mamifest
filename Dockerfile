FROM golang:alpine AS build
COPY entrypoint /go/src/entrypoint
WORKDIR /go/src/entrypoint
RUN go build

FROM eclipse-temurin:21-jre
RUN apt-get update && \
    apt-get install -y unzip rclone aria2 jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /FPS1
COPY installer.txt pack.txt user_jvm_args.txt /FPS1/
RUN aria2c -i installer.txt && \
    java -jar installer.jar --installServer && \
    rm -f installer*
RUN mkdir -p mods && \
    mkdir tmp && \
    aria2c -i pack.txt
RUN mv pack.zip tmp && \
    cd tmp && \
    unzip pack.zip && \
    cd .. && \
    mv tmp/overrides/* . && \
    mv tmp/manifest.json . && \
    rm -rf tmp
RUN cat manifest.json \
 | jq -r -c '.files[] | "https://www.curseforge.com/api/v1/mods/" + (.projectID|tostring) + "/files/" + (.fileID|tostring) + "/download"' \
 | wget --trust-server-names -i - -P mods
RUN echo 'eula=true' > eula.txt
# COPY server-icon.png /FPS1/
COPY server.properties backup.sh /FPS1/
COPY config /FPS1/config
# COPY mods /FPS1/mods
COPY --from=build /go/src/entrypoint/entrypoint /FPS1/entrypoint
RUN ln -s /data/ops.json ops.json && \
    ln -s /data/usercache.json usercache.json && \
    ln -s /data/whitelist.json whitelist.json
    # ln -s /data/discordchat.cfg config/discordchat.cfg
ENTRYPOINT [ "/FPS1/entrypoint" ]
