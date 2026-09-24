package main

import (
	"io"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
)

const prepare = true
const backup = false

func main() {
	//prepare.sh実行
	if prepare {
		preparecmd := exec.Command("./prepare.sh")
		preparecmd.Stdin = os.Stdin
		preparecmd.Stdout = os.Stdout
		preparecmd.Stderr = os.Stderr
		err := preparecmd.Run()
		if err != nil {
			if exitErr, ok := err.(*exec.ExitError); ok {
				log.Printf("prepare.sh returned non-zero code: %v", err)
				os.Exit(exitErr.ExitCode())
			} else {
				log.Printf("Failed to run prepare.sh: %v", err)
				os.Exit(2)
			}
		}
	}
	//javaコマンド定義
	startcmd := exec.Command("java", "@user_jvm_args.txt", "@libraries/net/neoforged/neoforge/21.1.251/unix_args.txt", "nogui", "\"$@\"")
	//パイプライン準備
	stdinpipe, err := startcmd.StdinPipe()
	if err != nil {
		log.Fatalf("Failed to set stdinpipe: %v", err)
	}
	go io.Copy(stdinpipe, os.Stdin)
	startcmd.Stdout = os.Stdout
	startcmd.Stderr = os.Stderr
	//スタート
	err = startcmd.Start()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			log.Printf("Server returned non-zero code during init: %v", err)
			os.Exit(exitErr.ExitCode())
		} else {
			log.Fatalf("Server failed during init: %v", err)
		}
	}
	//初期化監視
	waitCh := make(chan int)
	go func() {
		err = startcmd.Wait()
		if err != nil {
			if exitErr, ok := err.(*exec.ExitError); ok {
				log.Printf("Server returned non-zero code after init: %v", err)
				waitCh <- exitErr.ExitCode()
			} else {
				log.Printf("Server failed after init: %v", err)
				waitCh <- 1
			}
		} else {
			waitCh <- 0
		}
	}()
	//シグナル監視
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGTERM)
	exitCode := -1
	select {
	case <-sigCh:
		io.WriteString(stdinpipe, "\nstop\n")
		exitCode = <-waitCh
	case code := <-waitCh:
		exitCode = code
	}
	os.Exit(exitCode)
}
