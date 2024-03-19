.intel_syntax noprefix
.global _start

.section .text

_start:

//initialize socket
mov rax, 41
mov rdi, 2
mov rsi, 1
mov rdx, 0
syscall

//bind address to socket
mov rax, 49
mov rdi, 3
lea rsi, [server_address]
mov rdx, 16
syscall

//listen for connections
mov rax, 50
mov rdi, 3
mov rsi, 0
syscall

//loop to accept infinite connections
accept_loop:

//accept connection
mov rax, 43
mov rdi, 3
mov rsi, 0
mov rdx, 0
syscall

//fork
mov rax, 57
syscall

//verify process
cmp rax, 0
jz child

//parent process
parent:

//close socket
mov rax, 3
mov rdi, 4
syscall

jmp accept_loop

//accept connection
mov rax, 43
mov rdi, 3
mov rsi, 0
mov rdx, 0
syscall

//child process
child:

//close socket
mov rax, 3
mov rdi, 3
syscall

//read request
mov rax, 0
mov rdi, 4
lea rsi, [request]
mov rdx, 1024
syscall

//initialize variables
load_method:
lea rsi, [request]
lea rdi, [method]
mov rcx, 4

//parse request to extract method
parse_method:
mov al, byte ptr [rsi]
cmp al, ' '
je end_parse_method
mov byte ptr [rdi], al
inc rsi
inc rdi
jmp parse_method

//null terminate method
end_parse_method:
mov byte ptr [rdi], 0

//initialize variables
initailize_method:
lea rsi, [method]
lea rdi, [method_get]

//compare method and method_get strings
strcmp:
mov al, byte ptr [rsi]
mov bl, byte ptr [rdi]
cmp al, bl
je get
jmp post

//get method
get:

//move after method
lea rsi, [request + 4]
lea rdi, [file_path]

//parse to extract file path
parse_get:
mov al, byte ptr [rsi]
cmp al, 0
je end_parse_get
cmp al, 0x20
je end_parse_get
mov byte ptr [rdi], al
inc rsi
inc rdi
jmp parse_get

//null terminate file path
end_parse_get:
mov byte ptr [rdi], 0

//open file
mov rax, 2
lea rdi, [file_path]
mov rsi, 0
mov rdx, 0
syscall

//read file
mov rax, 0
mov rdi, 3
lea rsi, [file_path]
mov rdx, 256
syscall

//close accept
mov rax, 3
mov rdi, 3
syscall

//write status
mov rax, 1
mov rdi, 4
lea rsi, [response]
mov rdx, 19
syscall

//initialize counter
xor r8, r8

//count in file
count:
movzx rdx, byte ptr [file_path+r8]
test rdx, rdx
jz done
inc r8
jmp count

done:

//write content offile
mov rdi, 4
lea rsi, [file_path]
mov rdx, r8
mov rax, 1
syscall
jmp exit

post:
//parse post request
lea rsi, [request + 5]
lea rdi, [file_path]

//parse file path
parse_path:
mov al, byte ptr [rsi]
cmp al, 0
je end
cmp al, 0x20
je end_post
mov byte ptr [rdi], al
inc rsi
inc rdi
jmp parse_path

//null terminate file path
end_post:
mov byte ptr [rdi], 0

//open file
mov rax, 2
lea rdi, [file_path]
mov rsi, 65
mov rdx, 0777
syscall

//initialize variables
parse_post:
xor r9, r9
lea rsi, [request]
mov rcx, 1024

//search for pattern
search_pattern:
cmp byte ptr [rsi], 0x0D
jne not_found
cmp byte ptr [rsi+1], 0x0A
jne not_found
cmp byte ptr [rsi+2], 0x0D
jne not_found
cmp byte ptr [rsi+3], 0x0A
jne not_found
jmp found

//not found pattern
not_found:
inc rsi
jmp search_pattern

//found pattern
found:
lea rdi, [file_path-4]
mov r8, 0

//parse content of file
parse_content:
mov al, byte ptr [rsi]
cmp al, 0
je end_parse_content
cmp al, '"'
je end_parse_content
mov byte ptr [rdi], al
inc rsi
inc r8
inc rdi
jmp parse_content

//null terminate content
end_parse_content:
mov byte ptr [rdi], 0

//write file
mov rax, 1
mov rdi, 3
lea rsi, [file_path]
sub r8, 4
mov rdx, r8
syscall

//close accept
mov rax, 3
mov rdi, 3
syscall

//write status
mov rax, 1
mov rdi, 4
lea rsi, [response]
mov rdx, 19
syscall

exit:
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

response:
.string "HTTP/1.0 200 OK\r\n\r\n"

file:
.space 1024

file_path:
.space 1024

method:
.space 1024

method_get:
.string "GET"
