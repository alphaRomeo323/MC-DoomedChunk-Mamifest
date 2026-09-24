FROM golang:alpine AS build
COPY entrypoint /go/src/entrypoint
WORKDIR /go/src/entrypoint
RUN go build

FROM eclipse-temurin:21-jre
RUN apt-get update && \
    apt-get install -y unzip aria2 jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /doomedchunk
COPY installer.txt pack.txt user_jvm_args.txt /doomedchunk/
RUN aria2c -i installer.txt && \
    java -jar installer.jar --installServer && \
    rm -f *.bat *.sh *.txt installer*
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
    | jq -r -c '.files[] | "https://www.curseforge.com/api/v1/mods/" + (.projectID|tostring) + "/files/" + (.fileID|tostring) + "/download"' > mods.txt \
    && wget --trust-server-names -i mods.txt -P mods \
    && rm -f mods.txt
RUN echo 'eula=true' > eula.txt
# COPY server-icon.png /doomedchunk/
COPY server.properties prepare.sh /doomedchunk/
COPY config /doomedchunk/config
# COPY mods /doomedchunk/mods
COPY --from=build /go/src/entrypoint/entrypoint /doomedchunk/entrypoint
RUN ln -s /data/ops.json ops.json && \
    ln -s /data/usercache.json usercache.json && \
    ln -s /data/whitelist.json whitelist.json
    # ln -s /data/discordchat.cfg config/discordchat.cfg
ENTRYPOINT [ "/doomedchunk/entrypoint" ]
