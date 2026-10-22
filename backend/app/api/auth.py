from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from app.core.security import criar_access_token

router = APIRouter(prefix="/auth", tags=["Autenticação"])


@router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends()):
  # Exemplo simples de validação (substitua pela consulta real ao repositório/banco)
  if form_data.username != "admin" or form_data.password != "123456":
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Credenciais incorretas",
    )

  access_token = criar_access_token(data={"sub": form_data.username})
  return {"access_token": access_token, "token_type": "bearer"}