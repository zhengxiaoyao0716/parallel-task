package task_test

import (
	"fmt"
	"math/rand"
	"testing"
	"time"
)

//#region Emulate Process

type Process chan interface{}

func Spawn(recive func(self Process)) *Process {
	self := Process(make(chan interface{}))
	go recive(self)
	return &self
}
func Send(to Process, message interface{}) {
	go func() { to <- message }()
}

//#endregion

func play() {
	ping := Spawn(loop_ping)
	pong := Spawn(loop_pong)
	fmt.Println("ping-pong start!")
	Send(*ping, Message{0, *pong})
}
func loop_ping(self Process) {
	message := (<-self).(Message) // receive
	time.Sleep(1 * time.Second)
	next := rand.Intn(100)
	fmt.Printf("[ping]> back: %d, next: %d.\n", message.ball, next)
	Send(message.caller, Message{next, self})
	loop_ping(self)
}
func loop_pong(self Process) {
	message := (<-self).(Message) // receive
	back := message.ball + 1
	fmt.Printf("[pong]> received: %d, back %d.\n", message.ball, back)
	fmt.Println("")
	Send(message.caller, Message{back, self})
	loop_pong(self)
}

type Message struct {
	ball   int
	caller Process
}

func TestPingPong(t *testing.T) {
	play()
	select {}
}
