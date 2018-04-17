-module(recharge_notify_4_all).

-include("log.hrl").

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Transport, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->

    %% 读取客户端IP
    {Peer, _} = cowboy_req:peer(Req),
    ?DBG(background, "Peer=~p", [Peer]),
    %% 读取请求内容
    {ContentList, Req1} = cowboy_req:qs_vals(Req),
    ?ERR(account, "ContentList = ~p", [ContentList]),

    {_, ModuleBin} = lists:keyfind(<<"recharge_module">>, 1, ContentList),
    Module = list_to_atom(binary_to_list(ModuleBin)),

    {_, Req2} = 
    case catch Module:handle(lists:keydelete(<<"recharge_module">>, 1, ContentList), Req1) of
        {error, ErrMsg} when is_binary(ErrMsg) ->
            cowboy_req:reply(200, [{<<"content-encoding">>, <<"utf-8">>}], ErrMsg, Req1);
        {error, ErrMsg} when is_list(ErrMsg) ->
            cowboy_req:reply(200, [{<<"content-encoding">>, <<"utf-8">>}], unicode:characters_to_binary(ErrMsg), Req1);
        {error, {struct, ErrMsg}} ->
            cowboy_req:reply(200,[{<<"Content-Type">>, <<"application/json">>}], mochijson2:encode({struct, ErrMsg}), Req1);
        {ok, Message} when is_list(Message) ->
            cowboy_req:reply(200, [{<<"content-encoding">>, <<"utf-8">>}], unicode:characters_to_binary(Message), Req1);
        {ok, Message} when is_binary(Message) ->
            cowboy_req:reply(200, [{<<"content-encoding">>, <<"utf-8">>}], Message, Req1);
        {ok, {struct, Message}} ->
            cowboy_req:reply(200,[{<<"Content-Type">>, <<"application/json">>}], mochijson2:encode({struct, Message}), Req1)
    end,
    {ok, Req2, State}.

terminate(_Reason, _Req, _State) ->
	ok.