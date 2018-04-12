require 'message_helper'
RSpec.shared_examples_for "simple_instruction" do
	it { is_expected.to be_a IB::Messages::Incoming::AbstractMessage}
	its(:message_id) { is_expected.to eq 10 }
	its(:version) { is_expected.to eq 1 }
	its(:data) { is_expected.not_to  be_empty }
	its( :buffer  ){ is_expected.to be_empty }
end 
RSpec.describe IB::Messages::Incoming   do

		let( :simple_instruction ){   IB::Messages::Incoming.def_message  10  }
		let( :int_instruction ){   IB::Messages::Incoming.def_message 10, [:the_integer, :int] }
		let( :string_instruction ){   IB::Messages::Incoming.def_message 10, [:the_string, :string] }
		let( :decimal_instruction ){   IB::Messages::Incoming.def_message 10, [:the_decimal, :decimal] }
		let( :boolean_instruction ){   IB::Messages::Incoming.def_message 10, [:the_bool, :boolean] }
		let( :array_instruction ){   IB::Messages::Incoming.def_message 10, [:the_array, :array ] }
		let( :hash_instruction ){   IB::Messages::Incoming.def_message 10, [:the_hash, :hash] }


			#subject{ IB::Messages::Incoming.def_message 10 }

		context "simple Instruction" do
			subject{ simple_instruction.new ["1"] }
			it_behaves_like 'simple_instruction'
		end
		context "Instruction with Integer" do
			## only the correct behavior implements the function. Other cases yield zero (0)
			context "correct Behavior" do
				subject{ int_instruction.new ["1","45"] }
				it_behaves_like 'simple_instruction'
				its(:the_integer){ is_expected.to be_a(Integer).and eq(45) }
			end
			context "false Integer" do
				subject{ int_instruction.new ["1","zu"] }
				it_behaves_like 'simple_instruction'
				its(:the_integer){ is_expected.to be_a(Integer).and be_zero }
			end
			context "without value" do
				subject{ int_instruction.new ["1"]  }
				it_behaves_like 'simple_instruction'
				its(:the_integer){ is_expected.to be_nil } 
																									
			end
			context "with Blank" do
				subject{ int_instruction.new ["1", ""]  }
				it_behaves_like 'simple_instruction'
				its(:the_integer){ is_expected.to be_nil } 
			end
		end
		context "Instruction with String" do
			context "correct Behavior" do
				subject{ string_instruction.new ["1","zu"] }
				it_behaves_like 'simple_instruction'
				its(:the_string){ is_expected.to be_a(String).and eq("zu") }
			end
			context "false Integer" do
				subject{ string_instruction.new ["1","45"] }
				it_behaves_like 'simple_instruction'
				its(:the_string){ is_expected.to be_a(String).and eq("45") }
			end
			context "without value" do
				subject{ string_instruction.new ["1"]  }
				it_behaves_like 'simple_instruction'
				its(:the_string){ is_expected.to be_nil }
			end
			context "with Blank" do
				subject{ string_instruction.new ["1", ""]  }
				it_behaves_like 'simple_instruction'
				its(:the_string){ is_expected.to be_a(String).and be_empty }
			end
		end
		context "Instruction with Decimal" do
			context "correct Behavior" do
				subject{ decimal_instruction.new ["1","3.45"] }
				it_behaves_like 'simple_instruction'
				its(:the_decimal){ is_expected.to be_a(BigDecimal).and eq(3.45) }
			end
			context "false Integer" do
				subject{ decimal_instruction.new ["1","45"] }
				it_behaves_like 'simple_instruction'
				its(:the_decimal){ is_expected.to be_a(BigDecimal).and eq(45.0) }
			end
			context "without value" do
				subject{ decimal_instruction.new ["1"]  }
				it_behaves_like 'simple_instruction'
				its(:the_decimal){ is_expected.to be_nil }
			end
			context "with Blank" do
				subject{ decimal_instruction.new ["1", ""]  }
				it_behaves_like 'simple_instruction'
				its(:the_decimal){ is_expected.to be_nil }
			end
		end
		context "Instruction with Boolean" do
			context "correct true Behavior" do
				subject{ boolean_instruction.new ["1","1"] }
				it_behaves_like 'simple_instruction'
				its(:the_bool){ is_expected.to be_truthy }
			end
			context "correct false Behavior" do
				subject{ boolean_instruction.new ["1","0"] }
				it_behaves_like 'simple_instruction'
				its(:the_bool){ is_expected.to be_falsy }
			end
			context "false  String" do
				subject{ boolean_instruction.new ["1","Zted"] }
				it_behaves_like 'simple_instruction'
				its(:the_bool){ is_expected.to be_nil }
			end
			context "false  Integer" do
				subject{ boolean_instruction.new ["1","45"] }
				it_behaves_like 'simple_instruction'
				its(:the_bool){ is_expected.to be_nil }
			end
			context "without value" do
				subject{ boolean_instruction.new ["1"]  }
				it_behaves_like 'simple_instruction'
				its(:the_bool){ is_expected.to be_nil }
			end
			context "with Blank" do
				subject{ boolean_instruction.new ["1", ""]  }
				it_behaves_like 'simple_instruction'
				its(:the_bool){ is_expected.to be_nil }
			end
		end
		context "Instruction with Array" do
			context "correct empty Behavior" do
				subject{ array_instruction.new ["1","0"] }
				it_behaves_like 'simple_instruction'
				its(:the_array){ is_expected.to be_empty }
			end
			context "correct Behavior" do
				subject{ array_instruction.new ["1","2", "eins", "2"] }
				it_behaves_like 'simple_instruction'
				its(:the_array){ is_expected.to eq ["eins", '2'] }
			end
			context "false  String" do
				subject{ array_instruction.new ["1","Zted"] }   # perhaps request nil as answer?
				it_behaves_like 'simple_instruction'
				its(:the_array){ is_expected.to be_empty }
			end
			context "false  Integer" do
				subject{ array_instruction.new ["1","45"] }
				it_behaves_like 'simple_instruction'
				its(:the_array){ is_expected.to be_an(Array).and have(45).elements}
			end
			context "without value" do
				subject{ array_instruction.new ["1"]  }
				it_behaves_like 'simple_instruction'
				its(:the_array){ is_expected.to be_nil }
			end
			context "with Blank" do
				subject{ array_instruction.new ["1", ""]  }
				it_behaves_like 'simple_instruction'
				its(:the_array){ is_expected.to be_nil }
			end
		end
		context "Instruction with Hash" do
			context "correct empty Behavior" do
				subject{ hash_instruction.new ["1","0"] }
				it_behaves_like 'simple_instruction'
				its(:the_hash){ is_expected.to be_empty }
			end
			context "correct Behavior" do
				subject{ hash_instruction.new ["1","2", "eins", "2", "fuenf", "zurHeide"] }
				it_behaves_like 'simple_instruction'
				its(:the_hash){ is_expected.to eq :eins => '2', fuenf: 'zurHeide'  }
			end
			context "false  String" do
				subject{ hash_instruction.new ["1","Zted"] }   # perhaps request nil as answer?
				it_behaves_like 'simple_instruction'					 # now: because of "abc".to_i = 0 an empty hash is  created
				its(:the_hash){ is_expected.to be_empty }
			end
			context "false  Integer" do
				subject{ hash_instruction.new ["1","45"] }
				it_behaves_like 'simple_instruction'
				its(:the_hash){ is_expected.to be_a(Hash).and be_empty}
			end
			context "without value" do
				subject{ hash_instruction.new ["1"]  }
				it_behaves_like 'simple_instruction'
				its(:the_hash){ is_expected.to be_nil }
			end
			context "with Blank" do
				subject{ hash_instruction.new ["1", ""]  }
				it_behaves_like 'simple_instruction'
				its(:the_hash){ is_expected.to be_nil }
			end
		end
end
