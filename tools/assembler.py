import os
setup_file = ""
asm_file = ""

for file in os.listdir():
	if file.split(".")[1] == "asm":
		if asm_file != "":
			raise Exception("Cannot have duplicate assmeblerfiles")
		asm_file = file
	elif file.split(".")[1] == "set":
		if setup_file != "":
			raise Exception("Cannot have duplicate setupfiles")
		setup_file = file
if setup_file == "":
	raise Exception("No setup file")
if asm_file == "":
	raise Exception("No assembler file")
print("Files loaded:")
print("--------------------------------")
print(setup_file)
print(asm_file)
print("--------------------------------")

# Used to store instructions
class Instruction:
	def __init__(self, line):
		temp = line.split("\t")
		self.name = temp[0]
		self.addressing_modes = []
		for element in temp[1].split(","):
			self.addressing_modes.append(int(element))
		self.k1 = int(temp[2])
	def print_self(self):
		print("--------------")
		print("name: " + self.name)
		print("addressing modes: " + str(self.addressing_modes))
		print("k1 value: " + str(self.k1))
		print("--------------")

# loads in all the instructions from the setup file
op_codes = {}
setup_file_descriptor = open(setup_file)
for line in setup_file_descriptor.readlines():
	temp_op_code = Instruction(line)
	op_codes[temp_op_code.name] = temp_op_code
setup_file_descriptor.close()

# loads in the assembler file
asm_file_descriptor = open(asm_file)
instructions = []
for line in asm_file_descriptor.readlines():
	line_elements = line.split("\t")
	real_elements = []
	for element in line_elements:
		if element and element[0] != ";":
			if "\n" in element:
				real_elements.append(element.split("\n")[0])
			else:
				real_elements.append(element)
	if real_elements and real_elements[0]:
		instructions.append(real_elements)
pm = {}
counter = 0
names = {}
registers = {"G0":0, "G1":1, "G2":2, "G3":3}

for element in instructions:
	hex_counter = hex(counter).split("0x")[1]
	if len(hex_counter) == 1:
		hex_counter = "0" + hex_counter
	if element[0] == "SET":
		pm[element[1].lower()] = element[2]
		continue
	if element[0]=="SETI":
		pm[hex_counter] = element[1]
		counter += 1
		continue
	if ":" in element[0]:
		names[element[0].strip(":").lower()] = hex_counter
		continue
	if element[0] in ["LOAD", "ADD", "SUB", "AND", "CMP","COMB"]:
		op = op_codes[element[0]].k1
		reg = registers[element[1]]
		if "@" in element[2]:
			m = 2
		elif "$" in element[2]:
			m=1;
		else:
			m = 0
		op = op << 4
		reg = reg << 2
		tot = op + reg + m
		tot = hex(tot).split("0x")[1]
		if len(tot) == 1:
			tot = "0" + tot
		tot += element[2].strip("@").strip("$")
		pm[hex_counter] = tot
		counter += 1
		continue
	if element[0] in ["OUT","IN"]:
		op = op_codes[element[0]].k1
		reg = registers[element[1]]
		op = op << 4
		reg = reg << 2
		tot = op + reg
		tot = hex(tot).split("0x")[1]
		if len(tot) == 1:
			tot = "0" + tot
		tot+="00"
		pm[hex_counter] = tot
		counter += 1
		continue
	if element[0] in ["STORE"]:
		op = op_codes[element[0]].k1
		reg = registers[element[1]]
		if "@" in element[2]:
			m = 2
		else:
			m = 0
		op = op << 4
		reg = reg << 2
		tot = op + reg + m
		tot = hex(tot).split("0x")[1]
		if len(tot) == 1:
			tot = "0" + tot
		tot += element[2].strip("@")
		pm[hex_counter] = tot
		counter += 1
		continue
	if element[0] in ["STOREV"]:
		op = op_codes[element[0]].k1
		reg = registers[element[1]]
		m = 0
		op = op << 4
		reg = reg << 2
		tot = op + reg + m
		tot = hex(tot).split("0x")[1]
		if len(tot) == 1:
			tot = "0" + tot
		tot += "00"
		pm[hex_counter] = tot
		counter += 1
		continue
	if element[0]=="LSR":
		op = op_codes[element[0]].k1
		reg = registers[element[1]]
		if "@" in element[2]:
			m = 2
		elif "$" in element[2]:
			m=1;
		else:
			m = 0
		op = op << 4
		reg = reg << 2
		tot = op + reg + m
		tot = hex(tot).split("0x")[1]
		if len(tot) == 1:
			tot = "0" + tot
		tot += element[2].strip("@").strip("$")
		pm[hex_counter] = tot
		counter += 1
		continue	
	if element[0] in ["BRA","BNE","BGE","BEQ"]:
		op = op_codes[element[0]].k1
		reg = 0
		if "%" in element[1]:
			m = 3
		else:
			m = 0
		op = op << 4
		tot = op + reg + m
		tot = hex(tot).split("0x")[1]
		if len(tot) == 1:
			tot = "0" + tot
		tot += element[1].lower().strip("%")
		pm[hex_counter] = tot
		counter+=1
		continue
	if element[0]=="HALT":
		pm[hex_counter] = "8000"
		counter+=1
		continue
	else:
		print(element)
		raise Exception("something is fucky")		
		
	
	


# Write to all memory locations
try:
    os.remove("output.vhd")
except OSError:
    pass

output_file_descriptor = open("output.vhd", "w")
for i in range(256):
	temp_hex_value = hex(i).split("0x")[1]
	if len(temp_hex_value) == 1:
		temp_hex_value = "0" + temp_hex_value
	if temp_hex_value not in pm:
		output_file_descriptor.write('x"0000",\n')
	else:
		if pm[temp_hex_value][2:].lower() not in names:
			output_file_descriptor.write('x"'+ pm[temp_hex_value].lower() + '",\n')
		else:
			output_file_descriptor.write('x"' + pm[temp_hex_value][:2]+names[pm[temp_hex_value][2:].lower()] + '",\n')
output_file_descriptor.write("\n")

# end of program
print("------------------------------------")
print("output.vhd has been generated")
print("------------------------------------")
output_file_descriptor.close()
		
	

			
	


