import os
import resend

_FROM = "Automatize <onboarding@resend.dev>"


def enviar_codigo_reset(email: str, codigo: str) -> None:
    resend.api_key = os.getenv("RESEND_API_KEY", "")
    resend.Emails.send({
        "from": _FROM,
        "to": [email],
        "subject": f"{codigo} é seu código de redefinição — Automatize",
        "html": f"""
        <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px 24px;
                    background:#fff;border-radius:16px;border:1px solid #E9EDE9;">
          <h2 style="color:#112B46;margin:0 0 6px;font-size:22px;">Automatize</h2>
          <p style="color:#78838B;margin:0 0 28px;font-size:14px;">
            Recebemos um pedido de redefinição de senha para esta conta.
          </p>
          <div style="background:#F6F7F4;border-radius:12px;padding:28px 24px;
                      text-align:center;margin-bottom:28px;">
            <p style="color:#78838B;font-size:13px;margin:0 0 10px;">Código de verificação</p>
            <p style="color:#112B46;font-size:46px;font-weight:800;
                      letter-spacing:12px;margin:0;font-variant-numeric:tabular-nums;">
              {codigo}
            </p>
            <p style="color:#78838B;font-size:12px;margin:12px 0 0;">Válido por 15 minutos</p>
          </div>
          <p style="color:#78838B;font-size:13px;line-height:1.6;">
            Se não foi você quem solicitou, ignore este e-mail —
            sua senha permanece a mesma.
          </p>
        </div>
        """,
    })
