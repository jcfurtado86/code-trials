class_name CodeParser

const COMMAND_NAMES = {
	"andar": 0,
	"virar": 1,
	"pular": 2,
	"parar": 3,
	"esperar": 4,
	"repetir": 5,
	"se": 6,
}

const CONDITION_MAP = {
	"no_chao": "on_ground",
	"obstaculo_a_frente": "obstacle_ahead",
	"virado_direita": "facing_right",
	"virado_esquerda": "facing_left",
	"buraco_a_frente": "hole_ahead",
}

# === Resultado do parsing ===

class ParseResult:
	var success: bool = false
	var comandos: Array = []
	var error_message: String = ""
	var error_line: int = -1
	var command_count: int = 0

# === Nó fantasma que simula um draggable ===

class MockCommand extends TextureRect:
	var _command_type: int = 0
	var _valor: float = 1.0
	var _repeat_count: int = 1
	var _condition: String = ""
	var _inner_comandos: Array = []

	func get_command_type() -> int:
		return _command_type

	func get_valor() -> float:
		return _valor

	func get_repeat_count() -> int:
		return _repeat_count

	func get_condition() -> String:
		return _condition

	func get_comandos() -> Array:
		return _inner_comandos

# === Token ===

enum TokenType {
	IDENTIFIER,  # andar, virar, se, no_chao, etc.
	NUMBER,      # 3, 2.5
	LPAREN,      # (
	RPAREN,      # )
	LBRACE,      # {
	RBRACE,      # }
	SEMICOLON,   # ;
	EOF,
}

class Token:
	var type: int  # TokenType
	var value: String
	var line: int

	func _init(p_type: int, p_value: String, p_line: int):
		type = p_type
		value = p_value
		line = p_line

# === Tokenizer ===

static func _tokenize(code: String) -> Array:
	var tokens: Array = []
	var i := 0
	var line := 1
	var length := code.length()

	while i < length:
		var c = code[i]

		# Pular espaços e tabs
		if c == ' ' or c == '\t' or c == '\r':
			i += 1
			continue

		# Nova linha
		if c == '\n':
			line += 1
			i += 1
			continue

		# Comentários (// até fim da linha)
		if c == '/' and i + 1 < length and code[i + 1] == '/':
			while i < length and code[i] != '\n':
				i += 1
			continue

		# Símbolos
		if c == '(':
			tokens.append(Token.new(TokenType.LPAREN, "(", line))
			i += 1
			continue
		if c == ')':
			tokens.append(Token.new(TokenType.RPAREN, ")", line))
			i += 1
			continue
		if c == '{':
			tokens.append(Token.new(TokenType.LBRACE, "{", line))
			i += 1
			continue
		if c == '}':
			tokens.append(Token.new(TokenType.RBRACE, "}", line))
			i += 1
			continue
		if c == ';':
			tokens.append(Token.new(TokenType.SEMICOLON, ";", line))
			i += 1
			continue

		# Números (inteiros e decimais)
		if c.is_valid_float() or c == '.':
			var start = i
			while i < length and (code[i].is_valid_float() or code[i] == '.'):
				i += 1
			tokens.append(Token.new(TokenType.NUMBER, code.substr(start, i - start), line))
			continue

		# Identificadores (letras, underscore)
		if c == '_' or (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z'):
			var start = i
			while i < length:
				var ch = code[i]
				if ch == '_' or (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or ch.is_valid_float():
					i += 1
				else:
					break
			tokens.append(Token.new(TokenType.IDENTIFIER, code.substr(start, i - start), line))
			continue

		# Caractere desconhecido — pular
		i += 1

	tokens.append(Token.new(TokenType.EOF, "", line))
	return tokens

# === Parser ===

static func parse(code: String, available_commands: Array = []) -> ParseResult:
	var result = ParseResult.new()

	if code.strip_edges().is_empty():
		result.success = true
		result.comandos = []
		result.command_count = 0
		return result

	var tokens = _tokenize(code)
	var pos := [0]  # Array para passar por referência

	var comandos = _parse_programa(tokens, pos, available_commands, result)

	if not result.success and result.error_message.is_empty():
		# Parsing completou sem erro
		result.success = true
		result.comandos = comandos
		result.command_count = _count_commands(comandos)

	return result

static func _parse_programa(tokens: Array, pos: Array, available: Array, result: ParseResult) -> Array:
	var comandos: Array = []

	while pos[0] < tokens.size():
		var token: Token = tokens[pos[0]]

		if token.type == TokenType.EOF or token.type == TokenType.RBRACE:
			break

		var cmd = _parse_comando(tokens, pos, available, result)
		if not result.error_message.is_empty():
			result.success = false
			return []
		if cmd != null:
			comandos.append(cmd)

	return comandos

static func _parse_comando(tokens: Array, pos: Array, available: Array, result: ParseResult) -> Variant:
	var token: Token = tokens[pos[0]]

	if token.type != TokenType.IDENTIFIER:
		result.error_message = "Esperava um comando, encontrou '%s'" % token.value
		result.error_line = token.line
		return null

	var cmd_name = token.value.to_lower()

	# Validar se o comando existe
	if cmd_name not in COMMAND_NAMES:
		result.error_message = "Comando '%s' não existe" % cmd_name
		result.error_line = token.line
		return null

	# Validar se o comando está disponível no nível
	if available.size() > 0 and cmd_name not in available:
		result.error_message = "Comando '%s' não disponível neste nível" % cmd_name
		result.error_line = token.line
		return null

	var cmd_type = COMMAND_NAMES[cmd_name]

	match cmd_type:
		0, 1, 2, 3:  # andar, virar, pular, parar
			return _parse_simple(tokens, pos, cmd_type, result)
		4:  # esperar
			return _parse_esperar(tokens, pos, result)
		5:  # repetir
			return _parse_repetir(tokens, pos, available, result)
		6:  # se
			return _parse_se(tokens, pos, available, result)

	return null

static func _parse_simple(tokens: Array, pos: Array, cmd_type: int, result: ParseResult) -> Variant:
	var line = tokens[pos[0]].line
	pos[0] += 1  # consume identifier

	# Espera ()
	if not _expect(tokens, pos, TokenType.LPAREN, result):
		return null
	if not _expect(tokens, pos, TokenType.RPAREN, result):
		return null
	# ; é opcional
	if pos[0] < tokens.size() and tokens[pos[0]].type == TokenType.SEMICOLON:
		pos[0] += 1

	var mock = MockCommand.new()
	mock._command_type = cmd_type
	return [mock]

static func _parse_esperar(tokens: Array, pos: Array, result: ParseResult) -> Variant:
	pos[0] += 1  # consume "esperar"

	if not _expect(tokens, pos, TokenType.LPAREN, result):
		return null

	# Espera número
	if pos[0] >= tokens.size() or tokens[pos[0]].type != TokenType.NUMBER:
		result.error_message = "Esperava um número para esperar()"
		result.error_line = tokens[min(pos[0], tokens.size() - 1)].line
		return null

	var tempo = float(tokens[pos[0]].value)
	pos[0] += 1

	if not _expect(tokens, pos, TokenType.RPAREN, result):
		return null
	if pos[0] < tokens.size() and tokens[pos[0]].type == TokenType.SEMICOLON:
		pos[0] += 1

	var mock = MockCommand.new()
	mock._command_type = 4
	mock._valor = tempo
	return [mock, tempo]

static func _parse_repetir(tokens: Array, pos: Array, available: Array, result: ParseResult) -> Variant:
	pos[0] += 1  # consume "repetir"

	if not _expect(tokens, pos, TokenType.LPAREN, result):
		return null

	if pos[0] >= tokens.size() or tokens[pos[0]].type != TokenType.NUMBER:
		result.error_message = "Esperava um número para repetir()"
		result.error_line = tokens[min(pos[0], tokens.size() - 1)].line
		return null

	var count = int(tokens[pos[0]].value)
	pos[0] += 1

	if not _expect(tokens, pos, TokenType.RPAREN, result):
		return null
	if not _expect(tokens, pos, TokenType.LBRACE, result):
		return null

	# Parseia comandos internos
	var inner = _parse_programa(tokens, pos, available, result)
	if not result.error_message.is_empty():
		return null

	if not _expect(tokens, pos, TokenType.RBRACE, result):
		return null

	var mock = MockCommand.new()
	mock._command_type = 5
	mock._repeat_count = count
	mock._inner_comandos = inner
	return [mock, count, inner]

static func _parse_se(tokens: Array, pos: Array, available: Array, result: ParseResult) -> Variant:
	pos[0] += 1  # consume "se"

	if not _expect(tokens, pos, TokenType.LPAREN, result):
		return null

	if pos[0] >= tokens.size() or tokens[pos[0]].type != TokenType.IDENTIFIER:
		result.error_message = "Esperava uma condição para se()"
		result.error_line = tokens[min(pos[0], tokens.size() - 1)].line
		return null

	var cond_text = tokens[pos[0]].value.to_lower()
	pos[0] += 1

	if cond_text not in CONDITION_MAP:
		result.error_message = "Condição '%s' não existe. Use: %s" % [cond_text, ", ".join(CONDITION_MAP.keys())]
		result.error_line = tokens[pos[0] - 1].line
		return null

	var condition = CONDITION_MAP[cond_text]

	if not _expect(tokens, pos, TokenType.RPAREN, result):
		return null
	if not _expect(tokens, pos, TokenType.LBRACE, result):
		return null

	var inner = _parse_programa(tokens, pos, available, result)
	if not result.error_message.is_empty():
		return null

	if not _expect(tokens, pos, TokenType.RBRACE, result):
		return null

	var mock = MockCommand.new()
	mock._command_type = 6
	mock._condition = condition
	mock._inner_comandos = inner
	return [mock, condition]

# === Helpers ===

static func _expect(tokens: Array, pos: Array, expected_type: int, result: ParseResult) -> bool:
	if pos[0] >= tokens.size():
		result.error_message = "Fim inesperado do código"
		result.error_line = tokens[tokens.size() - 1].line
		return false

	var token: Token = tokens[pos[0]]
	if token.type != expected_type:
		var expected_name = _token_type_name(expected_type)
		result.error_message = "Esperava '%s', encontrou '%s'" % [expected_name, token.value]
		result.error_line = token.line
		return false

	pos[0] += 1
	return true

static func _token_type_name(type: int) -> String:
	match type:
		TokenType.LPAREN: return "("
		TokenType.RPAREN: return ")"
		TokenType.LBRACE: return "{"
		TokenType.RBRACE: return "}"
		TokenType.SEMICOLON: return ";"
		_: return "?"

static func _count_commands(comandos: Array) -> int:
	var total := 0
	for cmd in comandos:
		total += 1
		if cmd.size() >= 3 and cmd[0] is MockCommand:
			var mock: MockCommand = cmd[0]
			if mock._command_type == 5:  # repetir
				total += _count_commands(cmd[2])
			elif mock._command_type == 6:  # se
				# inner está no index 2 para se? não, está em _inner_comandos
				pass
		if cmd[0] is MockCommand:
			var mock: MockCommand = cmd[0]
			if mock._command_type == 6 and mock._inner_comandos.size() > 0:
				total += _count_commands(mock._inner_comandos)
	return total
