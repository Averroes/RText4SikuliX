/*
 * 07/14/2006
 *
 * LuaTokenMaker.java - Scanner for the Lua programming language.
 * 
 * This library is distributed under a modified BSD license.  See the included
 * RSyntaxTextArea.License.txt file for details.
 */
package org.fife.ui.rsyntaxtextarea.modes;

import java.io.*;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;


/**
 * Scanner for the Lua programming language.<p>
 *
 * This implementation was created using
 * <a href="http://www.jflex.de/">JFlex</a> 1.4.1; however, the generated file
 * was modified for performance.  Memory allocation needs to be almost
 * completely removed to be competitive with the handwritten lexers (subclasses
 * of <code>AbstractTokenMaker</code>, so this class has been modified so that
 * Strings are never allocated (via yytext()), and the scanner never has to
 * worry about refilling its buffer (needlessly copying chars around).
 * We can achieve this because RText always scans exactly 1 line of tokens at a
 * time, and hands the scanner this line as an array of characters (a Segment
 * really).  Since tokens contain pointers to char arrays instead of Strings
 * holding their contents, there is no need for allocating new memory for
 * Strings.<p>
 *
 * The actual algorithm generated for scanning has, of course, not been
 * modified.<p>
 *
 * If you wish to regenerate this file yourself, keep in mind the following:
 * <ul>
 *   <li>The generated <code>LuaTokenMaker.java</code> file will contain two
 *       definitions of both <code>zzRefill</code> and <code>yyreset</code>.
 *       You should hand-delete the second of each definition (the ones
 *       generated by the lexer), as these generated methods modify the input
 *       buffer, which we'll never have to do.</li>
 *   <li>You should also change the declaration/definition of zzBuffer to NOT
 *       be initialized.  This is a needless memory allocation for us since we
 *       will be pointing the array somewhere else anyway.</li>
 *   <li>You should NOT call <code>yylex()</code> on the generated scanner
 *       directly; rather, you should use <code>getTokenList</code> as you would
 *       with any other <code>TokenMaker</code> instance.</li>
 * </ul>
 *
 * @author Robert Futrell
 * @version 0.4
 *
 */
%%

%public
%class LuaTokenMaker
%extends AbstractJFlexTokenMaker
%unicode
%type org.fife.ui.rsyntaxtextarea.Token


%{


	/**
	 * Constructor.  This must be here because JFlex does not generate a
	 * no-parameter constructor.
	 */
	public LuaTokenMaker() {
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int tokenType) {
		addToken(zzStartRead, zzMarkedPos-1, tokenType);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param array The character array.
	 * @param start The starting offset in the array.
	 * @param end The ending offset in the array.
	 * @param tokenType The token's type.
	 * @param startOffset The offset in the document at which this token
	 *                    occurs.
	 */
	@Override
	public void addToken(char[] array, int start, int end, int tokenType, int startOffset) {
		super.addToken(array, start,end, tokenType, startOffset);
		zzStartRead = zzMarkedPos;
	}


	/**
	 * Returns the text to place at the beginning and end of a
	 * line to "comment" it in a this programming language.
	 *
	 * @return The start and end strings to add to a line to "comment"
	 *         it out.
	 */
	@Override
	public String[] getLineCommentStartAndEnd() {
		return new String[] { "--", null };
	}


	/**
	 * Returns the first token in the linked list of tokens generated
	 * from <code>text</code>.  This method must be implemented by
	 * subclasses so they can correctly implement syntax highlighting.
	 *
	 * @param text The text from which to get tokens.
	 * @param initialTokenType The token type we should start with.
	 * @param startOffset The offset into the document at which
	 *        <code>text</code> starts.
	 * @return The first <code>Token</code> in a linked list representing
	 *         the syntax highlighted text.
	 */
	public Token getTokenList(Segment text, int initialTokenType, int startOffset) {

		resetTokenList();
		this.offsetShift = -text.offset + startOffset;

		// Start off in the proper state.
		int state = Token.NULL;
		switch (initialTokenType) {
			case Token.COMMENT_MULTILINE:
				state = MLC;
				start = text.offset;
				break;
			case Token.LITERAL_STRING_DOUBLE_QUOTE:
				state = LONGSTRING;
				start = text.offset;
				break;
			default:
				state = Token.NULL;
		}

		s = text;
		try {
			yyreset(zzReader);
			yybegin(state);
			return yylex();
		} catch (IOException ioe) {
			ioe.printStackTrace();
			return new TokenImpl();
		}

	}


	/**
	 * Refills the input buffer.
	 *
	 * @return      <code>true</code> if EOF was reached, otherwise
	 *              <code>false</code>.
	 * @exception   IOException  if any I/O-Error occurs.
	 */
	private boolean zzRefill() throws java.io.IOException {
		return zzCurrentPos>=s.offset+s.count;
	}


	/**
	 * Resets the scanner to read from a new input stream.
	 * Does not close the old reader.
	 *
	 * All internal variables are reset, the old input stream 
	 * <b>cannot</b> be reused (internal buffer is discarded and lost).
	 * Lexical state is set to <tt>YY_INITIAL</tt>.
	 *
	 * @param reader   the new input stream 
	 */
	public final void yyreset(java.io.Reader reader) throws java.io.IOException {
		// 's' has been updated.
		zzBuffer = s.array;
		/*
		 * We replaced the line below with the two below it because zzRefill
		 * no longer "refills" the buffer (since the way we do it, it's always
		 * "full" the first time through, since it points to the segment's
		 * array).  So, we assign zzEndRead here.
		 */
		//zzStartRead = zzEndRead = s.offset;
		zzStartRead = s.offset;
		zzEndRead = zzStartRead + s.count - 1;
		zzCurrentPos = zzMarkedPos = zzPushbackPos = s.offset;
		zzLexicalState = YYINITIAL;
		zzReader = reader;
		zzAtBOL  = true;
		zzAtEOF  = false;
	}


%}

Letter					= [A-Za-z_]
Digit					= [0-9]

LineTerminator				= (\n)
WhiteSpace				= ([ \t\f])

UnclosedCharLiteral			= ([\']([^\'\n]|"\\'")*)
CharLiteral				= ({UnclosedCharLiteral}"'")
UnclosedStringLiteral		= ([\"]([^\"\n]|"\\\"")*)
StringLiteral				= ({UnclosedStringLiteral}[\"])
LongStringBegin			= ("[[")
LongStringEnd				= ("]]")

LineCommentBegin			= ("--")
MLCBegin					= ({LineCommentBegin}{LongStringBegin})

Number					= ( "."? {Digit} ({Digit}|".")* ([eE][+-]?)? ({Letter}|{Digit})* )
BooleanLiteral				= ("true"|"false")

Separator					= ([\(\)\{\}\[\]\]])
Separator2				= ([\;:,.])

ArithmeticOperator			= ("+"|"-"|"*"|"/"|"^"|"%")
RelationalOperator			= ("<"|">"|"<="|">="|"=="|"~=")
LogicalOperator			= ("and"|"or"|"not"|"#")
ConcatenationOperator		= ("..")
Elipsis					= ({ConcatenationOperator}".")
Operator					= ({ArithmeticOperator}|{RelationalOperator}|{LogicalOperator}|{ConcatenationOperator}|{Elipsis})

Identifier				= ({Letter}({Letter}|{Digit})*)


%state MLC
%state LONGSTRING
%state LINECOMMENT


%%

/* Keywords */
<YYINITIAL> "break"					{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "do"					{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "else"					{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "elseif"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "end"					{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "for"					{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "function"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "if"					{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "local"					{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "nil"					{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "repeat"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "return"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "then"					{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "until"					{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "while"					{ addToken(Token.RESERVED_WORD); }

/* Data types. */
<YYINITIAL> "<number>"				{ addToken(Token.DATA_TYPE); }
<YYINITIAL> "<name>"				{ addToken(Token.DATA_TYPE); }
<YYINITIAL> "<string>"				{ addToken(Token.DATA_TYPE); }
<YYINITIAL> "<eof>"					{ addToken(Token.DATA_TYPE); }
<YYINITIAL> "NULL"					{ addToken(Token.DATA_TYPE); }

/* Functions. */
<YYINITIAL> "_G"					{ addToken(Token.FUNCTION); }
<YYINITIAL> "_VERSION"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "assert"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "collectgarbage"			{ addToken(Token.FUNCTION); }
<YYINITIAL> "dofile"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "error"					{ addToken(Token.FUNCTION); }
<YYINITIAL> "getfenv"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "getmetatable"			{ addToken(Token.FUNCTION); }
<YYINITIAL> "ipairs"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "load"					{ addToken(Token.FUNCTION); }
<YYINITIAL> "loadfile"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "loadstring"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "module"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "next"					{ addToken(Token.FUNCTION); }
<YYINITIAL> "pairs"					{ addToken(Token.FUNCTION); }
<YYINITIAL> "pcall"					{ addToken(Token.FUNCTION); }
<YYINITIAL> "print"					{ addToken(Token.FUNCTION); }
<YYINITIAL> "rawequal"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "rawget"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "rawset"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "require"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "select"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "setfenv"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "setmetatable"			{ addToken(Token.FUNCTION); }
<YYINITIAL> "tonumber"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "tostring"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "type"					{ addToken(Token.FUNCTION); }
<YYINITIAL> "unpack"				{ addToken(Token.FUNCTION); }
<YYINITIAL> "xpcall"				{ addToken(Token.FUNCTION); }

/* Booleans. */
<YYINITIAL> {BooleanLiteral}			{ addToken(Token.LITERAL_BOOLEAN); }


<YYINITIAL> {

	{LineTerminator}				{ addNullToken(); return firstToken; }

	{WhiteSpace}+					{ addToken(Token.WHITESPACE); }

	/* String/Character literals. */
	{CharLiteral}					{ addToken(Token.LITERAL_CHAR); }
	{UnclosedCharLiteral}			{ addToken(Token.ERROR_CHAR); addNullToken(); return firstToken; }
	{StringLiteral}				{ addToken(Token.LITERAL_STRING_DOUBLE_QUOTE); }
	{UnclosedStringLiteral}			{ addToken(Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }
	{LongStringBegin}				{ start = zzMarkedPos-2; yybegin(LONGSTRING); }

	/* Comment literals. */
	{MLCBegin}					{ start = zzMarkedPos-4; yybegin(MLC); }
	{LineCommentBegin}				{ start = zzMarkedPos-2; yybegin(LINECOMMENT); }

	/* Separators. */
	{Separator}					{ addToken(Token.SEPARATOR); }
	{Separator2}					{ addToken(Token.IDENTIFIER); }

	/* Operators. */
	{Operator}					{ addToken(Token.OPERATOR); }

	/* Identifiers - Comes after Operators for "and", "not" and "or". */
	{Identifier}					{ addToken(Token.IDENTIFIER); }

	/* Numbers */
	{Number}						{ addToken(Token.LITERAL_NUMBER_FLOAT); }

	/* Ended with a line not in a string or comment. */
	<<EOF>>						{ addNullToken(); return firstToken; }

	/* Catch any other (unhandled) characters. */
	.							{ addToken(Token.IDENTIFIER); }

}


<MLC> {
	[^\n\]]+					{}
	\n						{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); return firstToken; }
	{LongStringEnd}			{ yybegin(YYINITIAL); addToken(start,zzStartRead+1, Token.COMMENT_MULTILINE); }
	\]						{}
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); return firstToken; }
}


<LONGSTRING> {
	[^\n\]]+					{}
	\n						{ addToken(start,zzStartRead-1, Token.LITERAL_STRING_DOUBLE_QUOTE); return firstToken; }
	{LongStringEnd}			{ yybegin(YYINITIAL); addToken(start,zzStartRead+1, Token.LITERAL_STRING_DOUBLE_QUOTE); }
	\]						{}
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.LITERAL_STRING_DOUBLE_QUOTE); return firstToken; }
}


<LINECOMMENT> {
	[^\n]+					{}
	\n						{ addToken(start,zzStartRead-1, Token.COMMENT_EOL); return firstToken; }
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.COMMENT_EOL); return firstToken; }
}
