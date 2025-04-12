// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debugger_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DebuggerState {

 bool get enabled; Disassembly get disassembly; int get PC; int get A; int get X; int get Y; int get SP; int get P; bool get C; bool get Z; bool get I; bool get D; bool get B; bool get V; bool get N; int get irq; bool get nmi; List<int> get stack; List<Breakpoint> get breakpoints; bool get canStepOut; int get scanline; int get cycle; int get v; int get t; int get x; bool get spriteOverflow; bool get sprite0Hit; bool get vBlank; bool get executionLogOpen; bool get showStack; int? get selectedAddress;
/// Create a copy of DebuggerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebuggerStateCopyWith<DebuggerState> get copyWith => _$DebuggerStateCopyWithImpl<DebuggerState>(this as DebuggerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebuggerState&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other.disassembly, disassembly)&&(identical(other.PC, PC) || other.PC == PC)&&(identical(other.A, A) || other.A == A)&&(identical(other.X, X) || other.X == X)&&(identical(other.Y, Y) || other.Y == Y)&&(identical(other.SP, SP) || other.SP == SP)&&(identical(other.P, P) || other.P == P)&&(identical(other.C, C) || other.C == C)&&(identical(other.Z, Z) || other.Z == Z)&&(identical(other.I, I) || other.I == I)&&(identical(other.D, D) || other.D == D)&&(identical(other.B, B) || other.B == B)&&(identical(other.V, V) || other.V == V)&&(identical(other.N, N) || other.N == N)&&(identical(other.irq, irq) || other.irq == irq)&&(identical(other.nmi, nmi) || other.nmi == nmi)&&const DeepCollectionEquality().equals(other.stack, stack)&&const DeepCollectionEquality().equals(other.breakpoints, breakpoints)&&(identical(other.canStepOut, canStepOut) || other.canStepOut == canStepOut)&&(identical(other.scanline, scanline) || other.scanline == scanline)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.v, v) || other.v == v)&&(identical(other.t, t) || other.t == t)&&(identical(other.x, x) || other.x == x)&&(identical(other.spriteOverflow, spriteOverflow) || other.spriteOverflow == spriteOverflow)&&(identical(other.sprite0Hit, sprite0Hit) || other.sprite0Hit == sprite0Hit)&&(identical(other.vBlank, vBlank) || other.vBlank == vBlank)&&(identical(other.executionLogOpen, executionLogOpen) || other.executionLogOpen == executionLogOpen)&&(identical(other.showStack, showStack) || other.showStack == showStack)&&(identical(other.selectedAddress, selectedAddress) || other.selectedAddress == selectedAddress));
}


@override
int get hashCode => Object.hashAll([runtimeType,enabled,const DeepCollectionEquality().hash(disassembly),PC,A,X,Y,SP,P,C,Z,I,D,B,V,N,irq,nmi,const DeepCollectionEquality().hash(stack),const DeepCollectionEquality().hash(breakpoints),canStepOut,scanline,cycle,v,t,x,spriteOverflow,sprite0Hit,vBlank,executionLogOpen,showStack,selectedAddress]);

@override
String toString() {
  return 'DebuggerState(enabled: $enabled, disassembly: $disassembly, PC: $PC, A: $A, X: $X, Y: $Y, SP: $SP, P: $P, C: $C, Z: $Z, I: $I, D: $D, B: $B, V: $V, N: $N, irq: $irq, nmi: $nmi, stack: $stack, breakpoints: $breakpoints, canStepOut: $canStepOut, scanline: $scanline, cycle: $cycle, v: $v, t: $t, x: $x, spriteOverflow: $spriteOverflow, sprite0Hit: $sprite0Hit, vBlank: $vBlank, executionLogOpen: $executionLogOpen, showStack: $showStack, selectedAddress: $selectedAddress)';
}


}

/// @nodoc
abstract mixin class $DebuggerStateCopyWith<$Res>  {
  factory $DebuggerStateCopyWith(DebuggerState value, $Res Function(DebuggerState) _then) = _$DebuggerStateCopyWithImpl;
@useResult
$Res call({
 bool enabled, Disassembly disassembly, int PC, int A, int X, int Y, int SP, int P, bool C, bool Z, bool I, bool D, bool B, bool V, bool N, int irq, bool nmi, List<int> stack, List<Breakpoint> breakpoints, bool canStepOut, int scanline, int cycle, int v, int t, int x, bool spriteOverflow, bool sprite0Hit, bool vBlank, bool executionLogOpen, bool showStack, int? selectedAddress
});




}
/// @nodoc
class _$DebuggerStateCopyWithImpl<$Res>
    implements $DebuggerStateCopyWith<$Res> {
  _$DebuggerStateCopyWithImpl(this._self, this._then);

  final DebuggerState _self;
  final $Res Function(DebuggerState) _then;

/// Create a copy of DebuggerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? disassembly = null,Object? PC = null,Object? A = null,Object? X = null,Object? Y = null,Object? SP = null,Object? P = null,Object? C = null,Object? Z = null,Object? I = null,Object? D = null,Object? B = null,Object? V = null,Object? N = null,Object? irq = null,Object? nmi = null,Object? stack = null,Object? breakpoints = null,Object? canStepOut = null,Object? scanline = null,Object? cycle = null,Object? v = null,Object? t = null,Object? x = null,Object? spriteOverflow = null,Object? sprite0Hit = null,Object? vBlank = null,Object? executionLogOpen = null,Object? showStack = null,Object? selectedAddress = freezed,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,disassembly: null == disassembly ? _self.disassembly : disassembly // ignore: cast_nullable_to_non_nullable
as Disassembly,PC: null == PC ? _self.PC : PC // ignore: cast_nullable_to_non_nullable
as int,A: null == A ? _self.A : A // ignore: cast_nullable_to_non_nullable
as int,X: null == X ? _self.X : X // ignore: cast_nullable_to_non_nullable
as int,Y: null == Y ? _self.Y : Y // ignore: cast_nullable_to_non_nullable
as int,SP: null == SP ? _self.SP : SP // ignore: cast_nullable_to_non_nullable
as int,P: null == P ? _self.P : P // ignore: cast_nullable_to_non_nullable
as int,C: null == C ? _self.C : C // ignore: cast_nullable_to_non_nullable
as bool,Z: null == Z ? _self.Z : Z // ignore: cast_nullable_to_non_nullable
as bool,I: null == I ? _self.I : I // ignore: cast_nullable_to_non_nullable
as bool,D: null == D ? _self.D : D // ignore: cast_nullable_to_non_nullable
as bool,B: null == B ? _self.B : B // ignore: cast_nullable_to_non_nullable
as bool,V: null == V ? _self.V : V // ignore: cast_nullable_to_non_nullable
as bool,N: null == N ? _self.N : N // ignore: cast_nullable_to_non_nullable
as bool,irq: null == irq ? _self.irq : irq // ignore: cast_nullable_to_non_nullable
as int,nmi: null == nmi ? _self.nmi : nmi // ignore: cast_nullable_to_non_nullable
as bool,stack: null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as List<int>,breakpoints: null == breakpoints ? _self.breakpoints : breakpoints // ignore: cast_nullable_to_non_nullable
as List<Breakpoint>,canStepOut: null == canStepOut ? _self.canStepOut : canStepOut // ignore: cast_nullable_to_non_nullable
as bool,scanline: null == scanline ? _self.scanline : scanline // ignore: cast_nullable_to_non_nullable
as int,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as int,v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as int,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,spriteOverflow: null == spriteOverflow ? _self.spriteOverflow : spriteOverflow // ignore: cast_nullable_to_non_nullable
as bool,sprite0Hit: null == sprite0Hit ? _self.sprite0Hit : sprite0Hit // ignore: cast_nullable_to_non_nullable
as bool,vBlank: null == vBlank ? _self.vBlank : vBlank // ignore: cast_nullable_to_non_nullable
as bool,executionLogOpen: null == executionLogOpen ? _self.executionLogOpen : executionLogOpen // ignore: cast_nullable_to_non_nullable
as bool,showStack: null == showStack ? _self.showStack : showStack // ignore: cast_nullable_to_non_nullable
as bool,selectedAddress: freezed == selectedAddress ? _self.selectedAddress : selectedAddress // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// @nodoc


class _DebuggerState implements DebuggerState {
  const _DebuggerState({this.enabled = false, final  Disassembly disassembly = const [], this.PC = 0, this.A = 0, this.X = 0, this.Y = 0, this.SP = 0, this.P = 0, this.C = false, this.Z = false, this.I = false, this.D = false, this.B = false, this.V = false, this.N = false, this.irq = 0, this.nmi = false, final  List<int> stack = const [], final  List<Breakpoint> breakpoints = const [], this.canStepOut = false, this.scanline = 0, this.cycle = 0, this.v = 0, this.t = 0, this.x = 0, this.spriteOverflow = false, this.sprite0Hit = false, this.vBlank = false, this.executionLogOpen = false, this.showStack = false, this.selectedAddress = null}): _disassembly = disassembly,_stack = stack,_breakpoints = breakpoints;
  

@override@JsonKey() final  bool enabled;
 final  Disassembly _disassembly;
@override@JsonKey() Disassembly get disassembly {
  if (_disassembly is EqualUnmodifiableListView) return _disassembly;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_disassembly);
}

@override@JsonKey() final  int PC;
@override@JsonKey() final  int A;
@override@JsonKey() final  int X;
@override@JsonKey() final  int Y;
@override@JsonKey() final  int SP;
@override@JsonKey() final  int P;
@override@JsonKey() final  bool C;
@override@JsonKey() final  bool Z;
@override@JsonKey() final  bool I;
@override@JsonKey() final  bool D;
@override@JsonKey() final  bool B;
@override@JsonKey() final  bool V;
@override@JsonKey() final  bool N;
@override@JsonKey() final  int irq;
@override@JsonKey() final  bool nmi;
 final  List<int> _stack;
@override@JsonKey() List<int> get stack {
  if (_stack is EqualUnmodifiableListView) return _stack;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stack);
}

 final  List<Breakpoint> _breakpoints;
@override@JsonKey() List<Breakpoint> get breakpoints {
  if (_breakpoints is EqualUnmodifiableListView) return _breakpoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_breakpoints);
}

@override@JsonKey() final  bool canStepOut;
@override@JsonKey() final  int scanline;
@override@JsonKey() final  int cycle;
@override@JsonKey() final  int v;
@override@JsonKey() final  int t;
@override@JsonKey() final  int x;
@override@JsonKey() final  bool spriteOverflow;
@override@JsonKey() final  bool sprite0Hit;
@override@JsonKey() final  bool vBlank;
@override@JsonKey() final  bool executionLogOpen;
@override@JsonKey() final  bool showStack;
@override@JsonKey() final  int? selectedAddress;

/// Create a copy of DebuggerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebuggerStateCopyWith<_DebuggerState> get copyWith => __$DebuggerStateCopyWithImpl<_DebuggerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebuggerState&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other._disassembly, _disassembly)&&(identical(other.PC, PC) || other.PC == PC)&&(identical(other.A, A) || other.A == A)&&(identical(other.X, X) || other.X == X)&&(identical(other.Y, Y) || other.Y == Y)&&(identical(other.SP, SP) || other.SP == SP)&&(identical(other.P, P) || other.P == P)&&(identical(other.C, C) || other.C == C)&&(identical(other.Z, Z) || other.Z == Z)&&(identical(other.I, I) || other.I == I)&&(identical(other.D, D) || other.D == D)&&(identical(other.B, B) || other.B == B)&&(identical(other.V, V) || other.V == V)&&(identical(other.N, N) || other.N == N)&&(identical(other.irq, irq) || other.irq == irq)&&(identical(other.nmi, nmi) || other.nmi == nmi)&&const DeepCollectionEquality().equals(other._stack, _stack)&&const DeepCollectionEquality().equals(other._breakpoints, _breakpoints)&&(identical(other.canStepOut, canStepOut) || other.canStepOut == canStepOut)&&(identical(other.scanline, scanline) || other.scanline == scanline)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.v, v) || other.v == v)&&(identical(other.t, t) || other.t == t)&&(identical(other.x, x) || other.x == x)&&(identical(other.spriteOverflow, spriteOverflow) || other.spriteOverflow == spriteOverflow)&&(identical(other.sprite0Hit, sprite0Hit) || other.sprite0Hit == sprite0Hit)&&(identical(other.vBlank, vBlank) || other.vBlank == vBlank)&&(identical(other.executionLogOpen, executionLogOpen) || other.executionLogOpen == executionLogOpen)&&(identical(other.showStack, showStack) || other.showStack == showStack)&&(identical(other.selectedAddress, selectedAddress) || other.selectedAddress == selectedAddress));
}


@override
int get hashCode => Object.hashAll([runtimeType,enabled,const DeepCollectionEquality().hash(_disassembly),PC,A,X,Y,SP,P,C,Z,I,D,B,V,N,irq,nmi,const DeepCollectionEquality().hash(_stack),const DeepCollectionEquality().hash(_breakpoints),canStepOut,scanline,cycle,v,t,x,spriteOverflow,sprite0Hit,vBlank,executionLogOpen,showStack,selectedAddress]);

@override
String toString() {
  return 'DebuggerState(enabled: $enabled, disassembly: $disassembly, PC: $PC, A: $A, X: $X, Y: $Y, SP: $SP, P: $P, C: $C, Z: $Z, I: $I, D: $D, B: $B, V: $V, N: $N, irq: $irq, nmi: $nmi, stack: $stack, breakpoints: $breakpoints, canStepOut: $canStepOut, scanline: $scanline, cycle: $cycle, v: $v, t: $t, x: $x, spriteOverflow: $spriteOverflow, sprite0Hit: $sprite0Hit, vBlank: $vBlank, executionLogOpen: $executionLogOpen, showStack: $showStack, selectedAddress: $selectedAddress)';
}


}

/// @nodoc
abstract mixin class _$DebuggerStateCopyWith<$Res> implements $DebuggerStateCopyWith<$Res> {
  factory _$DebuggerStateCopyWith(_DebuggerState value, $Res Function(_DebuggerState) _then) = __$DebuggerStateCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, Disassembly disassembly, int PC, int A, int X, int Y, int SP, int P, bool C, bool Z, bool I, bool D, bool B, bool V, bool N, int irq, bool nmi, List<int> stack, List<Breakpoint> breakpoints, bool canStepOut, int scanline, int cycle, int v, int t, int x, bool spriteOverflow, bool sprite0Hit, bool vBlank, bool executionLogOpen, bool showStack, int? selectedAddress
});




}
/// @nodoc
class __$DebuggerStateCopyWithImpl<$Res>
    implements _$DebuggerStateCopyWith<$Res> {
  __$DebuggerStateCopyWithImpl(this._self, this._then);

  final _DebuggerState _self;
  final $Res Function(_DebuggerState) _then;

/// Create a copy of DebuggerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? disassembly = null,Object? PC = null,Object? A = null,Object? X = null,Object? Y = null,Object? SP = null,Object? P = null,Object? C = null,Object? Z = null,Object? I = null,Object? D = null,Object? B = null,Object? V = null,Object? N = null,Object? irq = null,Object? nmi = null,Object? stack = null,Object? breakpoints = null,Object? canStepOut = null,Object? scanline = null,Object? cycle = null,Object? v = null,Object? t = null,Object? x = null,Object? spriteOverflow = null,Object? sprite0Hit = null,Object? vBlank = null,Object? executionLogOpen = null,Object? showStack = null,Object? selectedAddress = freezed,}) {
  return _then(_DebuggerState(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,disassembly: null == disassembly ? _self._disassembly : disassembly // ignore: cast_nullable_to_non_nullable
as Disassembly,PC: null == PC ? _self.PC : PC // ignore: cast_nullable_to_non_nullable
as int,A: null == A ? _self.A : A // ignore: cast_nullable_to_non_nullable
as int,X: null == X ? _self.X : X // ignore: cast_nullable_to_non_nullable
as int,Y: null == Y ? _self.Y : Y // ignore: cast_nullable_to_non_nullable
as int,SP: null == SP ? _self.SP : SP // ignore: cast_nullable_to_non_nullable
as int,P: null == P ? _self.P : P // ignore: cast_nullable_to_non_nullable
as int,C: null == C ? _self.C : C // ignore: cast_nullable_to_non_nullable
as bool,Z: null == Z ? _self.Z : Z // ignore: cast_nullable_to_non_nullable
as bool,I: null == I ? _self.I : I // ignore: cast_nullable_to_non_nullable
as bool,D: null == D ? _self.D : D // ignore: cast_nullable_to_non_nullable
as bool,B: null == B ? _self.B : B // ignore: cast_nullable_to_non_nullable
as bool,V: null == V ? _self.V : V // ignore: cast_nullable_to_non_nullable
as bool,N: null == N ? _self.N : N // ignore: cast_nullable_to_non_nullable
as bool,irq: null == irq ? _self.irq : irq // ignore: cast_nullable_to_non_nullable
as int,nmi: null == nmi ? _self.nmi : nmi // ignore: cast_nullable_to_non_nullable
as bool,stack: null == stack ? _self._stack : stack // ignore: cast_nullable_to_non_nullable
as List<int>,breakpoints: null == breakpoints ? _self._breakpoints : breakpoints // ignore: cast_nullable_to_non_nullable
as List<Breakpoint>,canStepOut: null == canStepOut ? _self.canStepOut : canStepOut // ignore: cast_nullable_to_non_nullable
as bool,scanline: null == scanline ? _self.scanline : scanline // ignore: cast_nullable_to_non_nullable
as int,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as int,v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as int,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,spriteOverflow: null == spriteOverflow ? _self.spriteOverflow : spriteOverflow // ignore: cast_nullable_to_non_nullable
as bool,sprite0Hit: null == sprite0Hit ? _self.sprite0Hit : sprite0Hit // ignore: cast_nullable_to_non_nullable
as bool,vBlank: null == vBlank ? _self.vBlank : vBlank // ignore: cast_nullable_to_non_nullable
as bool,executionLogOpen: null == executionLogOpen ? _self.executionLogOpen : executionLogOpen // ignore: cast_nullable_to_non_nullable
as bool,showStack: null == showStack ? _self.showStack : showStack // ignore: cast_nullable_to_non_nullable
as bool,selectedAddress: freezed == selectedAddress ? _self.selectedAddress : selectedAddress // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
