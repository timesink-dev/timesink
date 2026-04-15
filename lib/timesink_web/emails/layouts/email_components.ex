defmodule TimesinkWeb.EmailComponents do
  use Phoenix.Component

  @doc "Base email layout wrapper"
  slot :inner_block, required: true

  def layout(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <style>
          @font-face {
            font-family: 'Ano Regular Wide';
            src: url('https://timesinkpresents.com/fonts/ano/01001df7-8270-4d44-ad53-85091f1b6725.woff2') format('woff2');
            font-weight: normal;
            font-style: normal;
          }
          @font-face {
            font-family: 'Gangster Grotesk';
            src: url('https://timesinkpresents.com/fonts/gangster_grotesk/GangsterGrotesk-Light.woff2') format('woff2');
            font-weight: 300;
            font-style: normal;
          }
        </style>
      </head>
      <body style="margin:0;padding:0;background-color:#0a0a0a;font-family:'Gangster Grotesk',Georgia,serif;">
        <table
          width="100%"
          cellpadding="0"
          cellspacing="0"
          style="background-color:#0a0a0a;padding:48px 16px;"
        >
          <tr>
            <td align="center">
              <table width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;">
                <!-- Header -->
                <tr>
                  <td style="padding-bottom:32px;">
                    <p style="margin:0;font-family:'Ano Regular Wide',Georgia,serif;font-size:13px;letter-spacing:0.15em;text-transform:uppercase;color:#888888;">
                      TimeSink Presents
                    </p>
                  </td>
                </tr>
                <!-- Body -->
                <tr>
                  <td style="color:#e8e8e8;font-size:16px;line-height:1.7;font-family:'Gangster Grotesk',Georgia,serif;font-weight:300;">
                    {render_slot(@inner_block)}
                  </td>
                </tr>
                <!-- Footer -->
                <tr>
                  <td style="padding-top:48px;border-top:1px solid #1f1f1f;margin-top:48px;">
                    <p style="margin:0;font-size:12px;color:#555555;line-height:1.6;font-family:'Gangster Grotesk',Georgia,serif;font-weight:300;">
                      TimeSink Presents. Real audiences. Real time. Real cinema.<br />
                      Questions? Reply to this email.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end
end
