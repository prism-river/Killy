# TiDB craft

[![Build Status](https://travis-ci.org/prism-river/killy.svg?branch=master)](https://travis-ci.org/prism-river/killy)
[![Go Report Card](https://goreportcard.com/badge/github.com/prism-river/killy)](https://goreportcard.com/report/github.com/prism-river/killy)

## 需求

1. 监控数据的显示
2. 执行 SQL
3. 数据库表的显示

## Config

Copy the config.example.json to config.json and edit it.

## Instructions

```bash
cp -r config/* Server/
cp -r Killy Server/Plugins/
mkdir bin
ln -s /usr/bin/docker bin/docker-${DOCKER_VERSION}-ce
go build
./killy &
cd ./Server
./Cuberite
```

## API Specification

### TCP Messages

```go
// TCPMessage defines what a message that can be
// sent or received to/from LUA scripts
type TCPMessage struct {
	Cmd  string   `json:"cmd,omitempty"`
	Args []string `json:"args,omitempty"`
	// Id is used to associate requests & responses
	ID   int         `json:"id,omitempty"`
	Data interface{} `json:"data,omitempty"`
}
```

#### 监控

cmd == 'monitor'

#### 数据库

cmd == 'event' and args == ['table']
