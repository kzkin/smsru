defmodule Smsru do

  @host "http://sms.ru/"

  @actions %{
    send:      "sms/send?",
    balance:   "my/balance?",
    limit:     "my/limit?",
    get_token: "auth/get_token"
  }

  @send_msg %{
    100 => "Сообщение принято к отправке.",
    200 => "Неправильный api_id",
    201 => "Не хватает средств на лицевом счету",
    202 => "Неправильно указан получатель",
    203 => "Нет текста сообщения",
    204 => "Имя отправителя не согласовано с администрацией",
    205 => "Сообщение слишком длинное (превышает 8 СМС)",
    206 => "Будет превышен или уже превышен дневной лимит на отправку сообщений",
    207 => "На этот номер (или один из номеров) нельзя отправлять сообщения, либо указано более 100 номеров в списке получателей",
    208 => "Параметр time указан неправильно",
    209 => "Вы добавили этот номер (или один из номеров) в стоп-лист",
    210 => "Используется GET, где необходимо использовать POST",
    211 => "Метод не найден",
    220 => "Сервис временно недоступен, попробуйте чуть позже.",
    300 => "Неправильный token (возможно истек срок действия, либо ваш IP изменился)",
    301 => "Неправильный пароль, либо пользователь не найден",
    302 => "Пользователь авторизован, но аккаунт не подтвержден (пользователь не ввел код, присланный в регистрационной смс)"
  }

  def sms_send(to, text, from \\ nil, time \\ nil, test \\ false, partner_id \\ nil) do
    api_id = get_auth_params
    url = @host <> Map.get(@actions, :send)

    params = Map.new
    params = Map.put(params, :to, to)
    params = Map.put(params, :text, text)
    if not is_nil(from), do: params = Map.put(params, :from, from)
    if not is_nil(time), do: params = Map.put(params, :time, time)
    if test, do: params = Map.put(params, :test, 1)
    if not is_nil(partner_id), do: params = Map.put(params, :partner_id, partner_id)

    params = Map.merge(params, api_id)

    http_request(url <> URI.encode_query(params))
  end

  def get_balance do
    url = @host <> Map.get(@actions, :balance) <> URI.encode_query(get_auth_params())

    http_request(url)
  end

  def get_limit do
    url = @host <> Map.get(@actions, :limit) <> URI.encode_query(get_auth_params())

    http_request(url)
  end


  ### private defs

  defp http_request(url) do
    url = String.to_char_list(url)
    res_body = response_body(:httpc.request(url))
    res_body = String.split(res_body, "\n")

    [code | val] = res_body
    code = String.to_integer(code)

    if code == 100, do: val, else: raise(Map.get(@send_msg, code))
  end

  defp get_auth_params do
    api_id = Application.get_env(:smsru, :api_id)

    if is_nil(api_id), do: raise("Need api_id in config"), else: %{api_id: api_id}
  end

  defp response_body({:ok, { _, _, body}}) do
     List.to_string(body)
  end

end
