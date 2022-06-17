# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM sealights/golang-builder as builder
WORKDIR /src

# restore dependencies
COPY go.mod go.sum ./
RUN go mod download
ARG RM_DEV_SL_TOKEN=local
ENV RM_DEV_SL_TOKEN ${RM_DEV_SL_TOKEN}
ENV SEALIGHTS_LOG_LEVEL=info
ENV SEALIGHTS_LAB_ID="integ_master_813e_SLBoutique"
ENV SEALIGHTS_TEST_STAGE="Unit Tests"
COPY . .

# Skaffold passes in debug-oriented compiler flags
ARG SKAFFOLD_GO_GCFLAGS


RUN wget https://agents.sealights.co/slcli/latest/slcli-linux-amd64.tar.gz \
    && tar -xzvf slcli-linux-amd64.tar.gz \
    && chmod +x ./slcli
RUN wget https://agents.sealights.co/slgoagent/latest/slgoagent-linux-amd64.tar.gz \
    && tar -xzvf slgoagent-linux-amd64.tar.gz \
    && chmod +x ./slgoagent

RUN ./slcli config init --lang go --token $RM_DEV_SL_TOKEN



RUN if [[ $IS_PR -eq 0 ]]; then \
    echo "Check-in to repo"; \
    BUILD_NAME=$(date +%F_%T) && ./slcli config create-bsid --app "frontend" --build "$BUILD_NAME" --branch "master" ; \
else \ 
    echo "Pull request"; \
    ./slcli prConfig create-bsid --app "frontend" --targetBranch "${TARGET_BRANCH}" \
        --latestCommit "${LATEST_COMMIT}" --pullRequestNumber "${PR_NUMBER}" --repositoryUrl "${TARGET_REPO_URL}"; \
fi

RUN ./slcli scan  --bsid buildSessionId.txt --path-to-scanner ./slgoagent --workspacepath ./ --scm git --scmProvider github
RUN go test -v ./...
RUN go build -gcflags="${SKAFFOLD_GO_GCFLAGS}" -o /go/bin/frontend .

FROM alpine as release
RUN apk add --no-cache ca-certificates \
    busybox-extras net-tools bind-tools
WORKDIR /src
COPY --from=builder /go/bin/frontend /src/server
COPY ./templates ./templates
COPY ./static ./static

# Definition of this variable is used by 'skaffold debug' to identify a golang binary.
# Default behavior - a failure prints a stack trace for the current goroutine.
# See https://golang.org/pkg/runtime/
ENV GOTRACEBACK=single
ARG RM_DEV_SL_TOKEN=local
ENV RM_DEV_SL_TOKEN ${RM_DEV_SL_TOKEN}

EXPOSE 8080
ENTRYPOINT ["/src/server"]
