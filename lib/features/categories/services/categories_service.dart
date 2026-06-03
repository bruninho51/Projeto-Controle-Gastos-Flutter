import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';

class CategoriesService {
  final ApiService apiService;

  CategoriesService(this.apiService);

  Future<List<CategoriaGastoResponseDto>> getCategorias() =>
      apiService.getCategorias();

  Future<void> createCategoria(CategoriaGastoCreateDto dto) =>
      apiService.createCategoria(dto);

  Future<void> deleteCategoria(int id) => apiService.deleteCategoria(id);
}
