import * as admin from "firebase-admin";

admin.initializeApp();

export { crearImperio } from "./crearImperio";
export { mejorarEdificio } from "./mejorarEdificio";
export { pasarDiaPartida } from "./pasarDiaPartida";
export { pasarDiaAutomatico } from "./pasarDiaAutomatico";
export { desbloquearPasoDia } from "./desbloquearPasoDia";
export { seedDatosIniciales } from "./seedDatosIniciales";
export { fundarCiudad } from "./fundarCiudad";
export { cambiarImpuestosCiudad } from "./cambiarImpuestosCiudad";
export { obtenerTropasDisponibles } from "./obtenerTropasDisponibles";
export { moverTropasCiudad } from "./moverTropasCiudad";
export { comprarHeroe } from "./comprarHeroe";
export { asignarTropasHeroe } from "./asignarTropasHeroe";
export { quitarTropasHeroe } from "./quitarTropasHeroe";
