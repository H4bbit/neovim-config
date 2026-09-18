/**
 * pi-nvim-ext — extension pi para integração Neovim
 *
 * Carregada via: pi --mode rpc -e /caminho/abs/extensions/pi-nvim-ext.ts
 *
 * MVP: apenas valida que a extension carrega sem erro, lê $NVIM
 * e tenta conectar no socket msgpack-rpc do Neovim.
 *
 * Ferramentas reais (nvim_list_buffers, nvim_read_buffer, etc.)
 * serão adicionadas em commits subsequentes.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import net from "node:net";

export default function (pi: ExtensionAPI): void {
  const nvimAddr = process.env.NVIM;

  if (!nvimAddr) {
    process.stderr.write("[pi-nvim-ext] AVISO: $NVIM não definido — não foi possível conectar no socket do Neovim\n");
    return;
  }

  process.stderr.write(`[pi-nvim-ext] tentando conectar em ${nvimAddr}\n`);

  const socket = net.connect({ path: nvimAddr }, () => {
    process.stderr.write("[pi-nvim-ext] conexão estabelecida com o Neovim\n");
    socket.destroy(); // MVP: fecha após confirmação
  });

  socket.on("error", (err) => {
    process.stderr.write(`[pi-nvim-ext] ERRO na conexão: ${(err as Error).message}\n`);
  });

  socket.on("close", () => {
    process.stderr.write("[pi-nvim-ext] conexão fechada\n");
  });
}
