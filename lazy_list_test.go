package task_test

import (
	"fmt"
	"testing"
	"time"
)

type LazyList chan int

func NewLazyList(init int, iter func(prev int) int) *LazyList {
	ch := LazyList(make(chan int, 3))
	go ch.Yield(init, iter)
	return &ch
}
func (list *LazyList) Yield(next int, iter func(prev int) int) {
	fmt.Println("> before yield:", next)
	*list <- next
	fmt.Println("< after yield:", next)
	list.Yield(iter(next), iter)
}
func (list *LazyList) Get() int {
	return <-*list
}

func TestLazyList(*testing.T) {
	infiniteList := NewLazyList(0, func(prev int) int { return 1 + prev })
	for i := 0; i < 6; i++ {
		num := infiniteList.Get()
		fmt.Println("[received]:", num)
	}
	time.Sleep(100)
}
