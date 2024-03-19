.intel_syntax noprefix
.global _start

.section .text

_start:

//socket
mov rax, 41
mov rdi, 2
mov rsi, 1
mov rdx, 0
syscall

//bind
mov rax, 49
mov rdi, 3
lea rsi, [server_address]
mov rdx, 16
syscall

//listen
mov rax, 50
mov rdi, 3
mov rsi, 0
syscall

//accept
mov rax, 43
mov rdi, 3
mov rsi, 0
mov rdx, 0
syscall

//fork
mov rax, 57
syscall

cmp rax, 0
jz child

parent:

//close
mov rax, 3
mov rdi, 4
syscall

//accept
mov rax, 43
mov rdi, 3
mov rsi, 0
mov rdx, 0
syscall

child:

//close_socket
mov rax, 3
mov rdi, 3
syscall

//read
mov rax, 0
mov rdi, 4
lea rsi, [request]
mov rdx, 1024
syscall

//parse
lea rsi, [request + 4]
lea rdi, [file_path]
parse:
mov al, byte ptr [rsi]
cmp al, 0
je end
cmp al, 0x20
je end
mov byte ptr [rdi], al
inc rsi
inc rdi
jmp parse

end:
mov byte ptr [rdi], 0

//open
mov rax, 2
lea rdi, [file_path]
mov rsi, 0
mov rdx, 0
syscall

//read
mov rax, 0
mov rdi, 3
lea rsi, [file_path]
mov rdx, 256
syscall

//close_accept
mov rax, 3
mov rdi, 3
syscall

//write_status
mov rax, 1
mov rdi, 4
lea rsi, [response]
mov rdx, 19
syscall

//count_file
xor r8, r8
count:
movzx rdx, byte ptr [file_path+r8]
test rdx, rdx
jz done
inc r8
jmp count

done:

//write_file
mov rdi, 4
lea rsi, [file_path]
mov rdx, r8
mov rax, 1
syscall

//exit
mov rdi, 0
mov rax, 60
syscall

.section .data
server_address:
.short 0x02
.word 0x5000
.byte 0x00, 0x00, 0x00, 0x00

request:
.space 1024

file:
.space 1024

file_path:
.space 1024

response:
.string "HTTP/1.0 200 OK\r\n\r\n"
